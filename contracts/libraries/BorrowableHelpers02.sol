pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../interfaces/IBorrowable.sol";

struct BorrowableDetail {
    uint256 totalBorrows;
    uint256 totalBalance;
    uint256 kinkUtilizationRate;
    uint256 kinkBorrowRate;
    uint256 kinkMultiplier;
    uint256 reserveFactor;
}

library BorrowableHelpers {
    using SafeMath for uint256;
    using BorrowableDetailHelpers for BorrowableDetail;

    function borrowableValueOf(IBorrowable borrowable, uint256 underlyingAmount) internal returns (uint256) {
        if (underlyingAmount == 0) {
            return 0;
        }
        uint256 exchangeRate = borrowable.exchangeRate();
        return underlyingAmount.mul(1e18).div(exchangeRate);
    }

    function underlyingValueOf(IBorrowable borrowable, uint256 borrowableAmount) internal returns (uint256) {
        if (borrowableAmount == 0) {
            return 0;
        }
        uint256 exchangeRate = borrowable.exchangeRate();
        return borrowableAmount.mul(exchangeRate).div(1e18);
    }

    function underlyingBalanceOf(IBorrowable borrowable, address account) internal returns (uint256) {
        return underlyingValueOf(borrowable, borrowable.balanceOf(account));
    }

    function myUnderlyingBalance(IBorrowable borrowable) internal returns (uint256) {
        return underlyingValueOf(borrowable, borrowable.balanceOf(address(this)));
    }

    function getBorrowableDetail(IBorrowable borrowable) internal view returns (BorrowableDetail memory detail) {
        detail.totalBorrows = borrowable.totalBorrows();
        detail.totalBalance = borrowable.totalBalance();
        detail.kinkUtilizationRate = borrowable.kinkUtilizationRate();
        detail.kinkBorrowRate = borrowable.kinkBorrowRate();
        detail.kinkMultiplier = borrowable.KINK_MULTIPLIER();
        detail.reserveFactor = borrowable.reserveFactor();
    }

    function getCurrentSupplyRate(IBorrowable borrowable)
        internal
        view
        returns (
            uint256 supplyRate_,
            uint256 borrowRate_,
            uint256 utilizationRate_
        )
    {
        BorrowableDetail memory detail = getBorrowableDetail(borrowable);
        return detail.getSupplyRate();
    }
}

library BorrowableDetailHelpers {
    using SafeMath for uint256;

    uint256 private constant TEN_TO_18 = 1e18;

    function getBorrowRate(BorrowableDetail memory detail)
        internal
        pure
        returns (uint256 borrowRate_, uint256 utilizationRate_)
    {
        (borrowRate_, utilizationRate_) = getBorrowRate(
            detail.totalBorrows,
            detail.totalBalance,
            detail.kinkUtilizationRate,
            detail.kinkBorrowRate,
            detail.kinkMultiplier
        );
    }

    function getBorrowRate(
        uint256 totalBorrows,
        uint256 totalBalance,
        uint256 kinkUtilizationRate,
        uint256 kinkBorrowRate,
        uint256 kinkMultiplier
    ) internal pure returns (uint256 borrowRate_, uint256 utilizationRate_) {
        uint256 actualBalance = totalBorrows.add(totalBalance);

        utilizationRate_ = actualBalance == 0 ? 0 : totalBorrows.mul(TEN_TO_18).div(actualBalance);

        if (utilizationRate_ < kinkUtilizationRate) {
            borrowRate_ = kinkBorrowRate.mul(utilizationRate_).div(kinkUtilizationRate);
        } else {
            uint256 overUtilization = (utilizationRate_.sub(kinkUtilizationRate)).mul(TEN_TO_18).div(
                TEN_TO_18.sub(kinkUtilizationRate)
            );
            borrowRate_ = (((kinkMultiplier.sub(1)).mul(overUtilization)).add(TEN_TO_18)).mul(kinkBorrowRate).div(
                TEN_TO_18
            );
        }
    }

    function getSupplyRate(BorrowableDetail memory detail)
        internal
        pure
        returns (
            uint256 supplyRate_,
            uint256 borrowRate_,
            uint256 utilizationRate_
        )
    {
        return getNextSupplyRate(detail, 0, 0);
    }

    function getNextSupplyRate(
        BorrowableDetail memory detail,
        uint256 depositAmount,
        uint256 withdrawAmount
    )
        internal
        pure
        returns (
            uint256 supplyRate_,
            uint256 borrowRate_,
            uint256 utilizationRate_
        )
    {
        require(depositAmount == 0 || withdrawAmount == 0, "BH: INVLD_DELTA");

        (borrowRate_, utilizationRate_) = getBorrowRate(
            detail.totalBorrows,
            detail.totalBalance.add(depositAmount).sub(withdrawAmount),
            detail.kinkUtilizationRate,
            detail.kinkBorrowRate,
            detail.kinkMultiplier
        );

        supplyRate_ = borrowRate_.mul(utilizationRate_).div(TEN_TO_18).mul(TEN_TO_18.sub(detail.reserveFactor)).div(
            TEN_TO_18
        );
    }

    function getInterest(
        uint256 balance,
        uint256 supplyRate,
        uint256 actualBalance
    ) internal pure returns (uint256) {
        return TEN_TO_18.mul(balance).mul(supplyRate).div(actualBalance);
    }

    function getMyNetInterest(
        BorrowableDetail memory detail,
        uint256 myBalance,
        uint256 depositAmount,
        uint256 withdrawAmount
    ) internal pure returns (uint256 gain_, uint256 loss_) {
        require(depositAmount > 0 != withdrawAmount > 0, "BH: INVLD_DELTA");

        (uint256 currentSupplyRate, , ) = getSupplyRate(detail);
        if (currentSupplyRate == 0) {
            return (gain_ = 0, loss_ = 0);
        }
        (uint256 nextSupplyRate, , ) = getNextSupplyRate(detail, depositAmount, withdrawAmount);

        uint256 actualBalance = detail.totalBalance.add(detail.totalBorrows);

        uint256 currentInterest = getInterest(myBalance, currentSupplyRate, actualBalance);
        uint256 nextInterest = getInterest(
            myBalance.add(depositAmount).sub(withdrawAmount),
            nextSupplyRate,
            actualBalance.add(depositAmount).sub(withdrawAmount)
        );

        if (nextInterest > currentInterest) {
            gain_ = nextInterest.sub(currentInterest);
        } else {
            loss_ = currentInterest.sub(nextInterest);
        }
    }
}
