// SPDX-License-Identifier: MIT-License

pragma solidity =0.8.9;

import "./Borrowable.sol";
import "./Collateral.sol";

contract DeployHelper {
    function test() external pure returns(bytes32) {
        return keccak256(abi.encodePacked(type(Collateral).creationCode));
    }
}
