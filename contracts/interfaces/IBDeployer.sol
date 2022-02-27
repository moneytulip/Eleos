// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.9;

interface IBDeployer {
	function deployBorrowable(address uniswapV2Pair, uint8 index) external returns (address borrowable);
}