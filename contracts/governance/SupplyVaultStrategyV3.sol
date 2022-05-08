// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../libraries/StringHelpers.sol";
import "../libraries/MathHelpers.sol";
import "../libraries/BorrowableHelpers02.sol";
import "../interfaces/ISupplyVaultStrategy.sol";
import "../interfaces/IBorrowable.sol";
import "../interfaces/ISupplyVault.sol";
import "../interfaces/IFactory.sol";

contract SupplyVaultStrategyV3 is ISupplyVaultStrategy, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using BorrowableHelpers for IBorrowable;
    using BorrowableDetailHelpers for BorrowableDetail;

    struct SupplyVaultInfo {
        uint256 additionalDeallocAmount;
        uint256 minAllocAmount;
    }
    mapping(ISupplyVault => SupplyVaultInfo) public supplyVaultInfo;

    function updateSupplyVaultInfo(
        ISupplyVault supplyVault,
        uint256 additionalDeallocAmount,
        uint256 minAllocAmount
    ) external onlyOwner {
        require(isAuthorized[supplyVault], "SupplyVaultStrategyV3: INVALID_VAULT");

        supplyVaultInfo[supplyVault].additionalDeallocAmount = additionalDeallocAmount;
        supplyVaultInfo[supplyVault].minAllocAmount = minAllocAmount;
    }

    struct BorrowableOption {
        IBorrowable borrowable;
        uint256 underlyingAmount;
        uint256 borrowableAmount;
        uint256 minLoss;
        uint256 maxGain;
    }

    mapping(ISupplyVault => bool) public isAuthorized;

    function _authorize(ISupplyVault supplyVault) private {
        require(!isAuthorized[supplyVault], "SupplyVaultStrategyV3: ALREADY_AUTHORIZED");

        isAuthorized[supplyVault] = true;
    }

    function authorize(ISupplyVault supplyVault) external onlyOwner {
        _authorize(supplyVault);
    }

    function authorizeMany(ISupplyVault[] calldata supplyVaultList) external onlyOwner {
        for (uint256 i = 0; i < supplyVaultList.length; i++) {
            _authorize(supplyVaultList[i]);
        }
    }

    modifier onlyAuthorized() {
        require(isAuthorized[ISupplyVault(msg.sender)], "SupplyVaultStrategyV3: NOT_AUTHORIZED");

        _;
    }

    IFactory constant TAROT_FACTORY = IFactory(0xaFc0F83aBF95Fa4d90C10d3d6bb1FB692f5F9B72);

    function getBorrowable(address _address) external view override onlyAuthorized returns (IBorrowable) {
        ISupplyVault supplyVault = ISupplyVault(msg.sender);
        address underlying = address(supplyVault.underlying());

        // Treating _address as a UniswapV2Pair, try to get the lending pool from the known factory adress
        (bool initialized, , , address borrowable0, address borrowable1) = TAROT_FACTORY.getLendingPool(_address);
        if (initialized) {
            if (IBorrowable(borrowable0).underlying() == underlying) {
                return IBorrowable(borrowable0);
            }
            if (IBorrowable(borrowable1).underlying() == underlying) {
                return IBorrowable(borrowable1);
            }
        }

        require(false, "SupplyVaultStrategyV3: INVALID_BORROWABLE");
    }

    function getSupplyRate() external override onlyAuthorized returns (uint256 supplyRate_) {
        ISupplyVault supplyVault = ISupplyVault(msg.sender);
        IERC20 underlying = supplyVault.underlying();

        uint256 totalUnderlying = underlying.balanceOf(address(supplyVault));
        uint256 weightedSupplyRate = 0; // Underlying has a supply rate of zero

        uint256 numBorrowables = supplyVault.getBorrowablesLength();
        for (uint256 i = 0; i < numBorrowables; i++) {
            IBorrowable borrowable = supplyVault.borrowables(i);
            uint256 borrowableUnderlyingBalance = borrowable.underlyingBalanceOf(address(supplyVault));
            if (borrowableUnderlyingBalance > 0) {
                (uint256 borrowableSupplyRate, , ) = borrowable.getCurrentSupplyRate();
                weightedSupplyRate = weightedSupplyRate.add(borrowableUnderlyingBalance.mul(borrowableSupplyRate));
                totalUnderlying = totalUnderlying.add(borrowableUnderlyingBalance);
            }
        }

        if (totalUnderlying != 0) {
            supplyRate_ = weightedSupplyRate.div(totalUnderlying);
        }
    }

    function _allocate(uint256 amount) private {
        ISupplyVault supplyVault = ISupplyVault(msg.sender);

        if (amount == 0) {
            // Nothing to allocate
            return;
        }

        BorrowableOption memory best;
        best.minLoss = type(uint256).max;

        uint256 numBorrowables = supplyVault.getBorrowablesLength();
        require(numBorrowables > 0, "SupplyVaultStrategyV3: NO_BORROWABLES");

        for (uint256 i = 0; i < numBorrowables; i++) {
            IBorrowable borrowable = supplyVault.borrowables(i);
            if (!supplyVault.getBorrowableEnabled(borrowable)) {
                continue;
            }

            uint256 exchangeRate = borrowable.exchangeRate();

            uint256 borrowableMinUnderlying = exchangeRate.div(1E18).add(1);
            if (amount < borrowableMinUnderlying) {
                continue;
            }

            BorrowableDetail memory detail = borrowable.getBorrowableDetail();
            uint256 underlyingBalance = borrowable.balanceOf(address(supplyVault)).mul(exchangeRate).div(1E18);

            (uint256 gain, uint256 loss) = detail.getMyNetInterest(underlyingBalance, amount, 0);

            if (gain > best.maxGain || (best.maxGain == 0 && loss < best.minLoss)) {
                best.borrowable = borrowable;
                best.maxGain = gain;
                best.minLoss = loss;
            }
        }

        if (address(best.borrowable) != address(0)) {
            supplyVault.allocateIntoBorrowable(best.borrowable, amount);
        }
    }

    function allocate() public override onlyAuthorized {
        ISupplyVault supplyVault = ISupplyVault(msg.sender);

        IERC20 underlying = supplyVault.underlying();
        uint256 amount = underlying.balanceOf(address(supplyVault));

        if (amount < supplyVaultInfo[supplyVault].minAllocAmount) {
            return;
        }

        _allocate(amount);
    }

    struct DeallocOption {
        uint256 withdrawBorrowableAmount;
        uint256 withdrawBorrowableAmountAsUnderlying;
        uint256 exchangeRate;
        uint256 vaultBorrowableBalance;
    }

    /**
     * Deallocate from the least performing borrowable either:
     *    1) The amount of that borrowable to generate at least needAmount of underlying
     *    2) The maximum amount that can be withdrawn from that borrowable at this time
     */
    function _deallocateFromLowestSupplyRate(
        ISupplyVault supplyVault,
        uint256 numBorrowables,
        IERC20 underlying,
        uint256 needAmount
    ) private returns (uint256 deallocatedAmount) {
        BorrowableOption memory best;
        best.minLoss = type(uint256).max;

        for (uint256 i = 0; i < numBorrowables; i++) {
            IBorrowable borrowable = supplyVault.borrowables(i);

            DeallocOption memory option;
            option.exchangeRate = borrowable.exchangeRate();

            {
                option.vaultBorrowableBalance = borrowable.balanceOf(address(supplyVault));
                if (option.vaultBorrowableBalance == 0) {
                    continue;
                }
                uint256 borrowableUnderlyingBalance = underlying.balanceOf(address(borrowable));
                uint256 borrowableUnderlyingBalanceAsBorrowable = borrowableUnderlyingBalance.mul(1E18).div(
                    option.exchangeRate
                );
                if (borrowableUnderlyingBalanceAsBorrowable == 0) {
                    continue;
                }
                uint256 needAmountAsBorrowableIn = needAmount.mul(1E18).div(option.exchangeRate).add(1);

                option.withdrawBorrowableAmount = MathHelpers.min(
                    needAmountAsBorrowableIn,
                    option.vaultBorrowableBalance,
                    borrowableUnderlyingBalanceAsBorrowable
                );
                option.withdrawBorrowableAmountAsUnderlying = option
                    .withdrawBorrowableAmount
                    .mul(option.exchangeRate)
                    .div(1E18);
            }
            if (option.withdrawBorrowableAmountAsUnderlying == 0) {
                continue;
            }

            BorrowableDetail memory detail = borrowable.getBorrowableDetail();
            uint256 underlyingBalance = option.vaultBorrowableBalance.mul(option.exchangeRate).div(1E18);
            (uint256 gain, uint256 loss) = detail.getMyNetInterest(
                underlyingBalance,
                0,
                option.withdrawBorrowableAmountAsUnderlying
            );

            uint256 lossPerUnderlying = loss.mul(1e18).div(option.withdrawBorrowableAmountAsUnderlying);
            uint256 gainPerUnderlying = gain.mul(1e18).div(option.withdrawBorrowableAmountAsUnderlying);
            if (gainPerUnderlying > best.maxGain || (best.maxGain == 0 && lossPerUnderlying < best.minLoss)) {
                best.borrowable = borrowable;
                best.minLoss = lossPerUnderlying;
                best.maxGain = gainPerUnderlying;
                best.borrowableAmount = option.withdrawBorrowableAmount;
                best.underlyingAmount = option.withdrawBorrowableAmountAsUnderlying;
            }
        }

        require(best.minLoss < type(uint256).max, "SupplyVaultStrategyV3: INSUFFICIENT_CASH");

        uint256 beforeBalance = underlying.balanceOf(address(supplyVault));
        supplyVault.deallocateFromBorrowable(best.borrowable, best.borrowableAmount);
        uint256 afterBalance = underlying.balanceOf(address(supplyVault));
        require(afterBalance.sub(beforeBalance) == best.underlyingAmount, "Delta must match");

        return best.underlyingAmount;
    }

    function deallocate(uint256 needAmount) public override onlyAuthorized {
        require(needAmount > 0, "SupplyVaultStrategyV3: ZERO_AMOUNT");

        ISupplyVault supplyVault = ISupplyVault(msg.sender);
        IERC20 underlying = supplyVault.underlying();

        needAmount = needAmount.add(supplyVaultInfo[supplyVault].additionalDeallocAmount);

        uint256 numBorrowables = supplyVault.getBorrowablesLength();

        do {
            // Withdraw as much as we can from the lowest supply or fail if none is available
            uint256 withdraw = _deallocateFromLowestSupplyRate(supplyVault, numBorrowables, underlying, needAmount);
            // If we get here then we made some progress

            if (withdraw >= needAmount) {
                // We unwound a bit more than we needed as deallocation had to round up
                needAmount = 0;
            } else {
                // Update the remaining amount that we desire
                needAmount = needAmount.sub(withdraw);
            }

            if (needAmount == 0) {
                // We have enough so we are done
                break;
            }
            // Keep going and try a different borrowable
        } while (true);

        assert(needAmount == 0);
    }

    struct ReallocateInfo {
        IBorrowable deallocFromBorrowable;
        IBorrowable allocIntoBorrowable;
    }

    function getReallocateInfo(bytes calldata _data) private pure returns (ReallocateInfo memory info) {
        if (_data.length == 0) {
            // Use default empty addresses
        } else if (_data.length == 64) {
            info = abi.decode(_data, (ReallocateInfo));
            require(info.deallocFromBorrowable != info.allocIntoBorrowable, "SupplyVaultStrategyV3: SAME_IN_OUT");
        } else {
            require(false, "SupplyVaultStrategyV3: INVALID_DATA");
        }
    }

    function reallocate(uint256 _underlyingAmount, bytes calldata _data) external override onlyAuthorized {
        require(_underlyingAmount > 0, "SupplyVaultStrategyV3: ZERO_AMOUNT");

        ReallocateInfo memory info = getReallocateInfo(_data);
        ISupplyVault supplyVault = ISupplyVault(msg.sender);
        IERC20 underlying = supplyVault.underlying();

        uint256 underlyingBalance = underlying.balanceOf(address(supplyVault));
        if (underlyingBalance < _underlyingAmount) {
            uint256 deallocateAmount = _underlyingAmount.sub(underlyingBalance);

            if (address(info.deallocFromBorrowable) != address(0)) {
                // Deallocate from this specific borrowable
                uint256 deallocateBorrowableAmount = info.deallocFromBorrowable.borrowableValueOf(deallocateAmount);
                supplyVault.deallocateFromBorrowable(info.deallocFromBorrowable, deallocateBorrowableAmount);
            } else {
                deallocate(deallocateAmount);
            }
        }

        uint256 allocateAmount = MathHelpers.min(_underlyingAmount, underlying.balanceOf(address(supplyVault)));
        if (address(info.allocIntoBorrowable) != address(0)) {
            // Allocate into this specific borrowable
            supplyVault.allocateIntoBorrowable(info.allocIntoBorrowable, allocateAmount);
        } else {
            _allocate(allocateAmount);
        }
    }
}
