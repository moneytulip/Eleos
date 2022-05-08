// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IBorrowable.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IFeeProcessor.sol";
import "../interfaces/IFeeDistributor.sol";
import "../interfaces/ISupplyVault.sol";
import "../interfaces/ISplitter.sol";

contract FeeProcessor is Ownable, ReentrancyGuard, IFeeProcessor {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address constant ZERO_ADDRESS = address(0);
    IERC20 constant ZERO_ERC20 = IERC20(ZERO_ADDRESS);

    uint256 constant REWARD_SCALE = 100e16;
    uint256 constant MIN_REWARD = 0;
    uint256 constant MAX_REWARD = 2e16;

    IERC20 immutable AMPL;
    IERC20 immutable WETH;

    ISplitter m_claimable;
    IFeeDistributor m_feeDistributor;
    uint256 m_reward;

    struct UniswapV2Exchange {
        IUniswapV2Factory factory;
        uint256 swapFeeFactor;
    }
    UniswapV2Exchange[] m_dexList;
    mapping(IUniswapV2Factory => bool) m_dexEnabled;

    struct BorrowableInfo {
        bool enabled;
        uint160 reward;
    }
    IBorrowable[] m_borrowableList;
    mapping(IBorrowable => BorrowableInfo) m_borrowableInfo;

    mapping(IERC20 => IERC20) m_bridge;

    ISupplyVault[] m_supplyVaultList;
    mapping(ISupplyVault => bool) m_supplyVaultEnabled;

    constructor(
        IERC20 amplify,
        IERC20 weth,
        ISplitter claimable,
        IFeeDistributor feeDistributor,
        uint256 reward
    ) public {
        AMPL = amplify;
        WETH = weth;
        setClaimable(claimable);
        setFeeDistributor(feeDistributor);
        setReward(reward);
    }

    receive() external payable {
        require(false, "FeeProcessor: Should not receieve ETH");
    }

    function getBridgeToken(IERC20 token) private view returns (IERC20) {
        if (token == AMPL || token == WETH) {
            return AMPL;
        }
        IERC20 bridgeToken = m_bridge[token];
        if (bridgeToken != ZERO_ERC20) {
            return bridgeToken;
        }
        // Default to WETH as the bridge
        return WETH;
    }

    function addBridgeToken(IERC20 token, IERC20 bridgeToken) external override onlyOwner {
        require(token != AMPL, "FeeProcessor: INVALID_TOKEN_AMPL");
        require(token != WETH, "FeeProcessor: INVALID_TOKEN_WETH");
        require(token != bridgeToken, "FeeProcessor: INVALID_BRIDGE_TOKEN_SAME");
        require(bridgeToken != ZERO_ERC20, "FeeProcessor: INVALID_BRIDGE_TOKEN_ZERO");
        m_bridge[token] = bridgeToken;
    }

    function addDex(IUniswapV2Factory factory, uint256 swapFeeFactor) external override onlyOwner {
        require(!m_dexEnabled[factory], "FeeProcessor: DEX_ALREADY_ENABLED");
        require(swapFeeFactor >= 900 && swapFeeFactor <= 1000, "FeeProcessor: INVALID_SWAP_FEE_FACTOR");
        m_dexList.push(UniswapV2Exchange({factory: factory, swapFeeFactor: swapFeeFactor}));
        m_dexEnabled[factory] = true;
    }

    function _indexOfDex(IUniswapV2Factory factory) private view returns (uint256 index) {
        for (uint256 i = 0; i < m_dexList.length; i++) {
            if (m_dexList[i].factory == factory) {
                return i;
            }
        }
        require(false, "FeeProcessor: DEX_NOT_FOUND");
    }

    function removeDex(IUniswapV2Factory factory) external override onlyOwner {
        require(m_dexEnabled[factory], "FeeProcessor: DEX_NOT_ENABLED");
        uint256 index = _indexOfDex(factory);
        UniswapV2Exchange memory last = m_dexList[m_dexList.length - 1];
        m_dexList[index] = last;
        m_dexList.pop();
        delete m_dexEnabled[factory];
    }

    function dexListLength() external view override returns (uint256) {
        return m_dexList.length;
    }

    function dexFactory(uint256 index) external view override returns (IUniswapV2Factory) {
        return m_dexList[index].factory;
    }

    function dexSwapFeeFactor(uint256 index) external view override returns (uint256) {
        return m_dexList[index].swapFeeFactor;
    }

    function setClaimable(ISplitter claimable) public override onlyOwner {
        // NOTE: We allow ZERO_ADDRESS here to disable source

        m_claimable = claimable;

        emit SetClaimable(address(claimable));
    }

    function setFeeDistributor(IFeeDistributor feeDistributor) public override onlyOwner {
        require(address(feeDistributor) != ZERO_ADDRESS, "FeeProcessor: ZERO_ADDRESS");

        m_feeDistributor = feeDistributor;

        emit SetFeeDistributor(address(feeDistributor));
    }

    function setReward(uint256 reward) public override onlyOwner {
        _checkRewardRange(reward);

        m_reward = reward;

        emit SetReward(reward);
    }

    function _getReward(BorrowableInfo memory info) private view returns (uint256) {
        if (info.reward > 0) {
            return info.reward;
        }
        return m_reward;
    }

    function getReward(IBorrowable borrowable) public view override returns (uint256) {
        BorrowableInfo memory info = m_borrowableInfo[borrowable];
        require(info.enabled, "FeeProcessor: BORROWABLE_NOT_ENABLED");
        return _getReward(info);
    }

    function getDefaultReward() public view override returns (uint256) {
        return m_reward;
    }

    function _addBorrowable(IBorrowable borrowable, uint160 reward) private {
        require(!m_borrowableInfo[borrowable].enabled, "FeeProcessor: BORROWABLE_ALREADY_ENABLED");
        _checkRewardRange(reward);

        m_borrowableInfo[borrowable] = BorrowableInfo({enabled: true, reward: reward});
        m_borrowableList.push(borrowable);

        emit AddBorrowable(address(borrowable), reward);
    }

    function addBorrowable(IBorrowable borrowable) external override onlyOwner {
        _addBorrowable(borrowable, 0);
    }

    function addBorrowableWithReward(IBorrowable borrowable, uint160 reward) external override onlyOwner {
        _addBorrowable(borrowable, reward);
    }

    function addBorrowables(IBorrowable[] calldata borrowableList) external override onlyOwner {
        for (uint256 i = 0; i < borrowableList.length; i++) {
            IBorrowable borrowable = borrowableList[i];
            _addBorrowable(borrowable, 0);
        }
    }

    function updateBorrowable(IBorrowable borrowable, uint160 reward) external override onlyOwner {
        require(m_borrowableInfo[borrowable].enabled, "FeeProcessor: BORROWABLE_NOT_ENABLED");
        _checkRewardRange(reward);

        m_borrowableInfo[borrowable].reward = reward;

        emit UpdateBorrowable(address(borrowable), reward);
    }

    function _indexOfBorrowable(IBorrowable borrowable) private view returns (uint256 index) {
        for (uint256 i = 0; i < m_borrowableList.length; i++) {
            if (m_borrowableList[i] == borrowable) {
                return i;
            }
        }
        require(false, "FeeProcessor: BORROWABLE_NOT_FOUND");
    }

    function removeBorrowable(IBorrowable borrowable) external override onlyOwner {
        require(m_borrowableInfo[borrowable].enabled, "FeeProcessor: BORROWABLE_NOT_ENABLED");

        uint256 index = _indexOfBorrowable(borrowable);
        IBorrowable last = m_borrowableList[m_borrowableList.length - 1];
        m_borrowableList[index] = last;
        m_borrowableList.pop();
        delete m_borrowableInfo[borrowable];

        emit RemoveBorrowable(address(borrowable));
    }

    function borrowableListLength() external view override returns (uint256) {
        return m_borrowableList.length;
    }

    function borrowableListItem(uint256 index) external view override returns (IBorrowable) {
        return m_borrowableList[index];
    }

    function borrowableEnabled(IBorrowable borrowable) external view override returns (bool) {
        return m_borrowableInfo[borrowable].enabled;
    }

    function supplyVaultListLength() external view override returns (uint256) {
        return m_supplyVaultList.length;
    }

    function supplyVaultListItem(uint256 index) external view override returns (ISupplyVault) {
        return m_supplyVaultList[index];
    }

    function supplyVaultEnabled(ISupplyVault vault) external view override returns (bool) {
        return m_supplyVaultEnabled[vault];
    }

    function _addSupplyVault(ISupplyVault vault) private {
        require(!m_supplyVaultEnabled[vault], "FeeProcessor: VAULT_ENABLED");

        m_supplyVaultEnabled[vault] = true;
        m_supplyVaultList.push(vault);

        emit AddSupplyVault(address(vault));
    }

    function addSupplyVault(ISupplyVault vault) external override onlyOwner {
        _addSupplyVault(vault);
    }

    function addSupplyVaults(ISupplyVault[] calldata supplyVaultList) external override onlyOwner {
        for (uint256 i = 0; i < supplyVaultList.length; i++) {
            ISupplyVault vault = supplyVaultList[i];
            _addSupplyVault(vault);
        }
    }

    function _indexOfSupplyVault(ISupplyVault vault) private view returns (uint256 index) {
        uint256 count = m_supplyVaultList.length;
        for (uint256 i = 0; i < count; i++) {
            if (m_supplyVaultList[i] == vault) {
                return i;
            }
        }
        require(false, "FeeProcessor: SUPPLY_VAULT_NOT_FOUND");
    }

    function removeSupplyVault(ISupplyVault vault) external override onlyOwner {
        require(m_supplyVaultEnabled[vault], "FeeProcessor: VAULT_ENABLED");

        uint256 index = _indexOfSupplyVault(vault);
        ISupplyVault last = m_supplyVaultList[m_supplyVaultList.length - 1];
        m_supplyVaultList[index] = last;
        m_supplyVaultList.pop();
        delete m_supplyVaultEnabled[vault];

        emit RemoveSupplyVault(address(vault));
    }

    function _claim(address token) private {
        if (address(m_claimable) != address(0)) {
            m_claimable.claim(token);
        }
    }

    function processSupplyVault(ISupplyVault vault) public override nonReentrant {
        require(m_supplyVaultEnabled[vault], "FeeProcessor: VAULT_ENABLED");

        _claim(address(vault));

        uint256 share = IERC20(address(vault)).balanceOf(address(this));
        require(share > 0, "FeeProcessor: ZERO_SHARE");

        vault.leaveInKind(share);

        emit ProcessSupplyVault(msg.sender, address(vault), share);
    }

    function processBorrowable(IBorrowable borrowable, address to) public override nonReentrant {
        BorrowableInfo memory info = m_borrowableInfo[borrowable];
        require(info.enabled, "FeeProcessor: BORROWABLE_NOT_ENABLED");

        m_feeDistributor.claim();

        _claim(address(borrowable));

        // AMPL balance before any redemption
        uint256 gremlinBalanceBefore = AMPL.balanceOf(address(this));

        // Redeem Borrowable for underlying
        borrowable.transfer(address(borrowable), borrowable.balanceOf(address(this)));
        borrowable.redeem(address(this));

        {
            IERC20 token = IERC20(borrowable.underlying());
            uint256 tokenAmount = token.balanceOf(address(this));
            require(tokenAmount > 0, "FeeProcessor: ZERO_TOKEN_AMOUNT");

            // Convert whatever we received to AMPL
            _toAMPL(token, tokenAmount);
        }

        uint256 gremlinBalanceAfter = AMPL.balanceOf(address(this));
        // Net amount to use for reward
        uint256 gremlinBalanceChange = gremlinBalanceAfter.sub(gremlinBalanceBefore);
        // Now have AMPL so send reward to caller and rest to fee distributor

        uint256 reward = _getReward(info); // Reward rate for this borrowable
        uint256 rewardAmount = gremlinBalanceChange.mul(reward).div(REWARD_SCALE);
        if (rewardAmount > 0) {
            AMPL.safeTransfer(to, rewardAmount);
        }
        uint256 gremlinAmount = gremlinBalanceAfter.sub(rewardAmount);
        AMPL.safeTransfer(address(m_feeDistributor), gremlinAmount);

        emit ProcessBorrowable(msg.sender, address(borrowable), gremlinAmount, rewardAmount);
    }

    function _toAMPL(IERC20 token, uint256 amount) private returns (uint256 gremlinOut) {
        if (token == AMPL) {
            // We have AMPL so no-op
            gremlinOut = amount;
        } else {
            IERC20 bridgeToken = getBridgeToken(token);
            if (bridgeToken == AMPL) {
                // Swap for AMPL and we are done
                gremlinOut = _doOptimalSwap(token, AMPL, amount, address(this));
            } else {
                // Swap token for bridgeToken
                uint256 bridgeAmount = _doOptimalSwap(token, bridgeToken, amount, address(this));
                // Then try again recursively
                gremlinOut = _toAMPL(bridgeToken, bridgeAmount);
            }
        }
    }

    struct SwapInfo {
        IUniswapV2Pair pair;
        uint256 swapFeeFactor;
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 estimatedAmountOut;
    }

    /**
     * Swap amountIn of fromToken for toToken on whichever DEX gives us the best exchange rate.
     */
    function _doOptimalSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amountIn,
        address to
    ) private returns (uint256 amountOut) {
        SwapInfo memory swapInfo;

        uint256 dexCount = m_dexList.length;
        for (uint256 dexIndex = 0; dexIndex < dexCount; dexIndex++) {
            UniswapV2Exchange memory exchange = m_dexList[dexIndex];
            IUniswapV2Pair pair = IUniswapV2Pair(exchange.factory.getPair(address(fromToken), address(toToken)));

            if (address(pair) == ZERO_ADDRESS) {
                continue;
            }

            (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
            (uint256 reserveIn, uint256 reserveOut) = address(fromToken) == pair.token0()
                ? (reserve0, reserve1)
                : (reserve1, reserve0);

            if (reserveIn == 0 || reserveOut == 0) {
                continue;
            }

            uint256 estimatedAmountOut = getAmountOut(amountIn, reserveIn, reserveOut, exchange.swapFeeFactor);

            if (estimatedAmountOut > swapInfo.estimatedAmountOut) {
                swapInfo = SwapInfo({
                    pair: pair,
                    swapFeeFactor: exchange.swapFeeFactor,
                    reserveIn: reserveIn,
                    reserveOut: reserveOut,
                    estimatedAmountOut: estimatedAmountOut
                });
            }
        }

        require(address(swapInfo.pair) != ZERO_ADDRESS, "FeeProcessor: PAIR_NOT_FOUND");

        fromToken.safeTransfer(address(swapInfo.pair), amountIn);
        uint256 actualAmountIn = fromToken.balanceOf(address(swapInfo.pair)).sub(swapInfo.reserveIn);
        amountOut = getAmountOut(actualAmountIn, swapInfo.reserveIn, swapInfo.reserveOut, swapInfo.swapFeeFactor);

        (uint amount0Out, uint amount1Out) = address(fromToken) == swapInfo.pair.token0()
            ? (uint(0), amountOut)
            : (amountOut, uint(0));
        swapInfo.pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 swapFeeFactor
    ) internal pure returns (uint amountOut) {
        require(amountIn > 0, "FeeProcessor: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "FeeProcessor: INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn.mul(swapFeeFactor);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function _checkRewardRange(uint256 reward) private pure {
        require(reward >= MIN_REWARD && reward <= MAX_REWARD, "FeeProcessor: REWARD_OUT_OF_RANGE");
    }
}
