// SPDX-License-Identifier: MIT-License
pragma solidity =0.8.9;

import "./PoolToken.sol";
import "./CStorage.sol";
import "./CSetter.sol";
import "./interfaces/IBorrowable.sol";
import "./interfaces/ICollateral.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IAmplifyPriceOracle.sol";
import "./interfaces/IAmplifyCallee.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./libraries/UQ112x112.sol";
import "./libraries/Math.sol";

contract Collateral is PoolToken, CStorage, CSetter {
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    constructor() {}

    /*** Collateralization Model ***/

    // returns the prices of borrowable0's and borrowable1's underlyings with collateral's underlying as denom
    function getPrices()
        public
        virtual
        returns (uint256 price0, uint256 price1)
    {
        (uint224 twapPrice112x112, ) = IAmplifyPriceOracle(amplifyPriceOracle)
            .getResult(underlying);
        return _computePrice(twapPrice112x112);
    }

    function _calculateLiquidityAndShortfall(
        uint256 amountCollateral,
        uint256 amount0,
        uint256 amount1,
        uint256 price0,
        uint256 price1
    ) private view returns (uint256 liquidity, uint256 shortfall) {
        uint256 a = amount0.mul(price0).div(1e18);
        uint256 b = amount1.mul(price1).div(1e18);
        if (a < b) (a, b) = (b, a);
        a = a.mul(safetyMarginSqrt).div(1e18);
        b = b.mul(1e18).div(safetyMarginSqrt);
        uint256 collateralNeeded = a.add(b).mul(liquidationIncentive).div(1e18);

        if (amountCollateral >= collateralNeeded) {
            return (amountCollateral - collateralNeeded, 0);
        } else {
            return (0, collateralNeeded - amountCollateral);
        }
    }

    // returns liquidity in  collateral's underlying
    function _calculateLiquidity(
        uint256 amountCollateral,
        uint256 amount0,
        uint256 amount1
    ) internal returns (uint256 liquidity, uint256 shortfall) {
        (uint256 price0, uint256 price1) = getPrices();
        return
            _calculateLiquidityAndShortfall(
                amountCollateral,
                amount0,
                amount1,
                price0,
                price1
            );
    }

    /*** ERC20 ***/

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override {
        require(tokensUnlocked(from, value), "Amplify: INSUFFICIENT_LIQUIDITY");
        super._transfer(from, to, value);
    }

    function tokensUnlocked(address from, uint256 value)
        public
        virtual
        returns (bool)
    {
        uint256 _balance = balanceOf[from];
        if (value > _balance) return false;
        uint256 finalBalance = _balance - value;
        uint256 amountCollateral = finalBalance.mul(exchangeRate()).div(1e18);
        uint256 amount0 = IBorrowable(borrowable0).borrowBalance(from);
        uint256 amount1 = IBorrowable(borrowable1).borrowBalance(from);
        (, uint256 shortfall) = _calculateLiquidity(
            amountCollateral,
            amount0,
            amount1
        );
        return shortfall == 0;
    }

    /*** Collateral ***/

    function accountLiquidityAmounts(
        address borrower,
        uint256 amount0,
        uint256 amount1
    ) public returns (uint256 liquidity, uint256 shortfall) {
        if (amount0 == type(uint256).max)
            amount0 = IBorrowable(borrowable0).borrowBalance(borrower);
        if (amount1 == type(uint256).max)
            amount1 = IBorrowable(borrowable1).borrowBalance(borrower);
        uint256 amountCollateral = balanceOf[borrower].mul(exchangeRate()).div(
            1e18
        );
        return _calculateLiquidity(amountCollateral, amount0, amount1);
    }

    function accountLiquidity(address borrower)
        public
        virtual
        returns (uint256 liquidity, uint256 shortfall)
    {
        return
            accountLiquidityAmounts(
                borrower,
                type(uint256).max,
                type(uint256).max
            );
    }

    function exchangeRate() public view virtual override returns (uint256) {
        if (totalSupply == 0 || totalBalance == 0) return initialExchangeRate;
        return totalBalance.mul(1e18).div(totalSupply);
    }

    function _computePrice(uint224 twapPrice112x112)
        private
        view
        returns (uint256 price0, uint256 price1)
    {
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(underlying)
            .getReserves();
        uint256 collateralTotalSupply = IUniswapV2Pair(underlying)
            .totalSupply();
        uint224 currentPrice112x112 = UQ112x112.encode(reserve1).uqdiv(
            reserve0
        );
        uint256 adjustmentSquared = uint256(twapPrice112x112).mul(2**32).div(
            currentPrice112x112
        );
        uint256 adjustment = Math.sqrt(adjustmentSquared.mul(2**32));

        uint256 currentBorrowable0Price = uint256(collateralTotalSupply)
            .mul(1e18)
            .div(reserve0 * 2);
        uint256 currentBorrowable1Price = uint256(collateralTotalSupply)
            .mul(1e18)
            .div(reserve1 * 2);

        price0 = currentBorrowable0Price.mul(adjustment).div(2**32);
        price1 = currentBorrowable1Price.mul(2**32).div(adjustment);

        /*
         * Price calculation errors may happen in some edge pairs where
         * reserve0 / reserve1 is close to 2**112 or 1/2**112
         * We're going to prevent users from using pairs at risk from the UI
         */
        require(price0 > 100, "Amplify: PRICE_CALCULATION_ERROR");
        require(price1 > 100, "Amplify: PRICE_CALCULATION_ERROR");
    }

    function accountLiquidityStale(address borrower)
        public
        view
        virtual
        returns (uint256 liquidity, uint256 shortfall)
    {
        uint256 amount0 = IBorrowable(borrowable0).borrowBalance(borrower);
        uint256 amount1 = IBorrowable(borrowable1).borrowBalance(borrower);
        uint256 amountCollateral = balanceOf[borrower].mul(exchangeRate()).div(
            1e18
        );
        (uint224 twapPrice112x112, ) = IAmplifyPriceOracle(amplifyPriceOracle)
            .getResultStale(underlying);
        (uint256 price0, uint256 price1) = _computePrice(twapPrice112x112);

        return
            _calculateLiquidityAndShortfall(
                amountCollateral,
                amount0,
                amount1,
                price0,
                price1
            );
    }

    function canBorrow(
        address borrower,
        address borrowable,
        uint256 accountBorrows
    ) public virtual returns (bool) {
        address _borrowable0 = borrowable0;
        address _borrowable1 = borrowable1;
        require(
            borrowable == _borrowable0 || borrowable == _borrowable1,
            "Amplify: INVALID_BORROWABLE"
        );
        uint256 amount0 = borrowable == _borrowable0
            ? accountBorrows
            : type(uint256).max;
        uint256 amount1 = borrowable == _borrowable1
            ? accountBorrows
            : type(uint256).max;
        (, uint256 shortfall) = accountLiquidityAmounts(
            borrower,
            amount0,
            amount1
        );
        return shortfall == 0;
    }

    // this function must be called from borrowable0 or borrowable1
    function seize(
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256 seizeTokens) {
        require(
            msg.sender == borrowable0 || msg.sender == borrowable1,
            "Amplify: UNAUTHORIZED"
        );

        (, uint256 shortfall) = accountLiquidity(borrower);
        require(shortfall > 0, "Amplify: INSUFFICIENT_SHORTFALL");

        uint256 price;
        if (msg.sender == borrowable0) (price, ) = getPrices();
        else (, price) = getPrices();

        seizeTokens = repayAmount
            .mul(liquidationIncentive)
            .div(1e18)
            .mul(price)
            .div(exchangeRate());

        balanceOf[borrower] = balanceOf[borrower].sub(
            seizeTokens,
            "Amplify: LIQUIDATING_TOO_MUCH"
        );
        balanceOf[liquidator] = balanceOf[liquidator].add(seizeTokens);
        emit Transfer(borrower, liquidator, seizeTokens);
    }

    // this low-level function should be called from another contract
    function flashRedeem(
        address redeemer,
        uint256 redeemAmount,
        bytes calldata data
    ) external nonReentrant update {
        require(redeemAmount <= totalBalance, "Amplify: INSUFFICIENT_CASH");

        // optimistically transfer funds
        _safeTransfer(redeemer, redeemAmount);
        if (data.length > 0)
            IAmplifyCallee(redeemer).amplifyRedeem(msg.sender, redeemAmount, data);

        uint256 redeemTokens = balanceOf[address(this)];
        uint256 declaredRedeemTokens = redeemAmount
            .mul(1e18)
            .div(exchangeRate())
            .add(1); // rounded up
        require(
            redeemTokens >= declaredRedeemTokens,
            "Amplify: INSUFFICIENT_REDEEM_TOKENS"
        );

        _burn(address(this), redeemTokens);
        emit Redeem(msg.sender, redeemer, redeemAmount, redeemTokens);
    }
}
