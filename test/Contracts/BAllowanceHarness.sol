pragma solidity =0.6.6;

import "../../contracts/BAllowance.sol";

contract BAllowanceHarness is BAllowance {
    constructor(string memory _name, string memory _symbol)
        public
        EleosERC20()
    {
        _setName(_name, _symbol);
    }

    function checkBorrowAllowance(
        address owner,
        address spender,
        uint256 amount
    ) external {
        super._checkBorrowAllowance(owner, spender, amount);
    }
}
