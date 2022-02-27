// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.9;

interface ICDeployer {
	function deployCollateral(address uniswapV2Pair) external returns (address collateral);
}