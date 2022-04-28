pragma solidity =0.8.9;

interface IClaimable {
	function claim() external returns (uint amount);
	event Claim(address indexed account, uint amount);
}