pragma solidity =0.8.9;
pragma experimental ABIEncoderV2;

import "./Distributor.sol";

contract InitializedDistributor is Distributor {
	
	using SafeMath for uint256;

	struct Shareholder {
		address recipient;
		uint shares;
	}

	constructor (
		address imx_,
		address claimable_,
		bytes[] memory data
	) public Distributor(imx_, claimable_) {
		uint _totalShares = 0;
		for (uint i = 0; i < data.length; i++) {
			Shareholder memory shareholder = abi.decode(data[i], (Shareholder));
			recipients[shareholder.recipient].shares = shareholder.shares;
			_totalShares = _totalShares.add(shareholder.shares);
		}
		totalShares = _totalShares;
	}

}