// SPDX-License-Identifier: MIT-License
pragma solidity =0.8.9;

import "../../contracts/interfaces/IAmplifyCallee.sol";
import "./Recipient.sol";

contract AmplifyCallee is IAmplifyCallee {
    address recipient;
    address underlying;

    constructor(address _recipient, address _underlying) public {
        recipient = _recipient;
        underlying = _underlying;
    }

    function amplifyBorrow(
        address sender,
        address borrower,
        uint256 borrowAmount,
        bytes calldata data
    ) external override {
        sender;
        borrower;
        borrowAmount;
        data;
        Recipient(recipient).empty(underlying, msg.sender);
    }

    function amplifyRedeem(
        address sender,
        uint256 redeemAmount,
        bytes calldata data
    ) external override {
        sender;
        redeemAmount;
        data;
        Recipient(recipient).empty(underlying, msg.sender);
    }
}
