pragma solidity =0.8.9;

import "../interfaces/IAmpl.sol";
import "../interfaces/IClaimable.sol";

contract MockClaimable is IClaimable {

	address public immutable imx;
	address public recipient;
	
	constructor(
		address imx_,
		address recipient_
	) public {
		imx = imx_;
		recipient = recipient_;
	}

	function setRecipient(address recipient_) public {
		recipient = recipient_;
	}

	function claim() public override returns (uint amount) {
		amount = IAmpl(imx).balanceOf(address(this));
		IAmpl(imx).transfer(recipient, amount);
	}
}