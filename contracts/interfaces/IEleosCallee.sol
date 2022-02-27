// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.9;

interface IEleosCallee {
    function eleosBorrow(
        address sender,
        address borrower,
        uint256 borrowAmount,
        bytes calldata data
    ) external;

    function eleosRedeem(
        address sender,
        uint256 redeemAmount,
        bytes calldata data
    ) external;
}
