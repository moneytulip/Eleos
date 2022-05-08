// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IFeeDistributor {
    function amplify() external view returns (address);

    function xAMPL() external view returns (address);

    function periodLength() external view returns (uint);

    function lastClaim() external view returns (uint);

    function claim() external returns (uint amount);

    function setPeriodLength(uint newPeriodLength) external;

    event Claim(uint previousBalance, uint timeElapsed, uint amount);
    event NewPeriodLength(uint oldPeriodLength, uint newPeriodLength);
}
