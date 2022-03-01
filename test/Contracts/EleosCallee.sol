// SPDX-License-Identifier: MIT-License
pragma solidity =0.8.9;

import "../../contracts/interfaces/IEleosCallee.sol";
import "./Recipient.sol";

contract EleosCallee is IEleosCallee {
    address recipient;
    address underlying;

    constructor(address _recipient, address _underlying) public {
        recipient = _recipient;
        underlying = _underlying;
    }

    function eleosBorrow(
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

    function eleosRedeem(
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
