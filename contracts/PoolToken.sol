// SPDX-License-Identifier: MIT-License

pragma solidity =0.8.9;

import "./AmplifyERC20.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IPoolToken.sol";
import "./libraries/SafeMath.sol";

contract PoolToken is AmplifyERC20 {
    using SafeMath for uint256;

    event Mint(
        address indexed sender,
        address indexed minter,
        uint256 mintAmount,
        uint256 mintTokens
    );
    event Redeem(
        address indexed sender,
        address indexed redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    );
    event Sync(uint256 totalBalance);

    uint256 internal constant initialExchangeRate = 1e18;
    address public underlying;
    address public factory;
    uint256 public totalBalance;
    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    /*** Initialize ***/

    // called once by the factory
    function _setFactory() external {
        require(factory == address(0), "Amplify: FACTORY_ALREADY_SET");
        factory = msg.sender;
    }

    /*** PoolToken ***/

    function _update() internal virtual {
        totalBalance = IERC20(underlying).balanceOf(address(this));
        emit Sync(totalBalance);
    }

    function exchangeRate() public virtual returns (uint256) {
        uint256 _totalSupply = totalSupply; // gas savings
        uint256 _totalBalance = totalBalance; // gas savings
        if (_totalSupply == 0 || _totalBalance == 0) return initialExchangeRate;
        return _totalBalance.mul(1e18).div(_totalSupply);
    }

    // this low-level function should be called from another contract
    function mint(address minter)
        external
        virtual
        nonReentrant
        update
        returns (uint256 mintTokens)
    {
        uint256 balance = IERC20(underlying).balanceOf(address(this));
        uint256 mintAmount = balance.sub(totalBalance);
        mintTokens = mintAmount.mul(1e18).div(exchangeRate());

        if (totalSupply == 0) {
            // permanently lock the first MINIMUM_LIQUIDITY tokens
            mintTokens = mintTokens.sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY);
        }
        require(mintTokens > 0, "Amplify: MINT_AMOUNT_ZERO");
        _mint(minter, mintTokens);
        emit Mint(msg.sender, minter, mintAmount, mintTokens);
    }

    // this low-level function should be called from another contract
    function redeem(address redeemer)
        external
        virtual
        nonReentrant
        update
        returns (uint256 redeemAmount)
    {
        uint256 redeemTokens = balanceOf[address(this)];
        redeemAmount = redeemTokens.mul(exchangeRate()).div(1e18);

        require(redeemAmount > 0, "Amplify: REDEEM_AMOUNT_ZERO");
        require(redeemAmount <= totalBalance, "Amplify: INSUFFICIENT_CASH");
        _burn(address(this), redeemTokens);
        _safeTransfer(redeemer, redeemAmount);
        emit Redeem(msg.sender, redeemer, redeemAmount, redeemTokens);
    }

    // force real balance to match totalBalance
    function skim(address to) external nonReentrant {
        _safeTransfer(
            to,
            IERC20(underlying).balanceOf(address(this)).sub(totalBalance)
        );
    }

    // force totalBalance to match real balance
    function sync() external virtual nonReentrant update {}

    /*** Utilities ***/

    // same safe transfer function used by UniSwapV2 (with fixed underlying)
    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    function _safeTransfer(address to, uint256 amount) internal {
        (bool success, bytes memory data) = underlying.call(
            abi.encodeWithSelector(SELECTOR, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Amplify: TRANSFER_FAILED"
        );
    }

    // prevents a contract from calling itself, directly or indirectly.
    bool internal _notEntered = true;
    modifier nonReentrant() {
        require(_notEntered, "Amplify: REENTERED");
        _notEntered = false;
        _;
        _notEntered = true;
    }

    // update totalBalance with current balance
    modifier update() {
        _;
        _update();
    }
}
