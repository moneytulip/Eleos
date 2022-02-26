pragma solidity =0.6.6;

import "./interfaces/ICStorage.sol";

contract CStorage is ICStorage {
	address public override borrowable0;
	address public override borrowable1;
	address public override eleosPriceOracle;
	uint public override safetyMarginSqrt = 1.58113883e18; //safetyMargin: 250%
	uint public override liquidationIncentive = 1.04e18; //4%
}