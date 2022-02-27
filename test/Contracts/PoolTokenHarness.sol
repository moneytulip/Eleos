pragma solidity =0.8.9;

import "../../contracts/PoolToken.sol";

contract PoolTokenHarness is PoolToken {
	function setUnderlying(address _underlying) public {
		underlying = _underlying;
	}
}