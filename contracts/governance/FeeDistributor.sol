// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../interfaces/IFeeDistributor.sol";

contract FeeDistributor is IFeeDistributor, Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public immutable override amplify;
    address public immutable override xAMPL;
    uint public override periodLength;
    uint public override lastClaim;

    constructor(
        address amplify_,
        address xAMPL_,
        uint periodLength_
    ) public {
        amplify = amplify_;
        xAMPL = xAMPL_;
        periodLength = periodLength_;
        lastClaim = block.timestamp;
    }

    function claim() external override returns (uint amount) {
        uint timeElapsed = block.timestamp.sub(lastClaim);
        lastClaim = block.timestamp;
        uint balance = IERC20(amplify).balanceOf(address(this));
        if (timeElapsed > periodLength) {
            amount = balance;
        } else {
            amount = balance.mul(timeElapsed).div(periodLength);
        }
        if (amount > 0) {
            IERC20(amplify).safeTransfer(xAMPL, amount);
        }
        emit Claim(balance, timeElapsed, amount);
    }

    function setPeriodLength(uint newPeriodLength) external override onlyOwner {
        emit NewPeriodLength(periodLength, newPeriodLength);
        periodLength = newPeriodLength;
    }
}
