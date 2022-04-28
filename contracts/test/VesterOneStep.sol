pragma solidity =0.8.9;

import "../interfaces/IAmpl.sol";
import "../interfaces/IClaimable.sol";
import "../interfaces/IVester.sol";

contract VesterOneStep is IClaimable {

	uint public constant segments = 1;

	address public immutable imx;
	address public recipient;

	uint public immutable vestingAmount;
	uint public immutable vestingBegin;
	uint public immutable vestingEnd;
	
	constructor(
		address imx_,
		address recipient_,
		uint vestingAmount_,
		uint vestingBegin_,
		uint vestingEnd_
	) public {
		imx = imx_;
		recipient = recipient_;

		vestingAmount = vestingAmount_;
		vestingBegin = vestingBegin_;
		vestingEnd = vestingEnd_;
	}

	function setRecipient(address recipient_) public {
		recipient = recipient_;
	}

	function claim() public override returns (uint amount) {
		require(msg.sender == recipient, "Vester: UNAUTHORIZED");
		uint blockTimestamp = getBlockTimestamp();
		if (blockTimestamp < vestingBegin) return 0;
		amount = IAmpl(imx).balanceOf(address(this));
		IAmpl(imx).transfer(recipient, amount);
	}
	
	uint _blockTimestamp;
	function getBlockTimestamp() public virtual view returns (uint) {
		return _blockTimestamp;
	}
	function setBlockTimestamp(uint blockTimestamp) public {
		_blockTimestamp = blockTimestamp;
	}
}
