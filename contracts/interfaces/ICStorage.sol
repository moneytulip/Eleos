// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.9;

interface ICStorage {
    function borrowable0() external view returns (address);

    function borrowable1() external view returns (address);

    function eleosPriceOracle() external view returns (address);

    function safetyMarginSqrt() external view returns (uint256);

    function liquidationIncentive() external view returns (uint256);
}
