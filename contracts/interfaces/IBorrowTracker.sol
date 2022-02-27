// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.9;

interface IBorrowTracker {
	function trackBorrow(address borrower, uint borrowBalance, uint borrowIndex) external;
}