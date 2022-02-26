pragma solidity =0.6.6;

import "../../contracts/PoolToken.sol";

contract PoolTokenHarness is PoolToken {
	function setUnderlying(address _underlying) public {
		underlying = _underlying;
	}
}