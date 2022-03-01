// SPDX-License-Identifier: MIT-License
pragma solidity =0.8.9;

import "./interfaces/ICStorage.sol";

contract CStorage {
	address public borrowable0;
	address public borrowable1;
	address public eleosPriceOracle;
	uint public safetyMarginSqrt = 1.58113883e18; //safetyMargin: 250%
	uint public liquidationIncentive = 1.04e18; //4%
}