pragma solidity =0.5.16;

import "../../contracts/EleosERC20.sol";

contract EleosERC20Harness is EleosERC20 {
    constructor(string memory _name, string memory _symbol)
        public
        EleosERC20()
    {
        _setName(_name, _symbol);
    }

    function mint(address to, uint256 value) public {
        super._mint(to, value);
    }

    function burn(address from, uint256 value) public {
        super._burn(from, value);
    }

    function setBalanceHarness(address account, uint256 amount) external {
        balanceOf[account] = amount;
    }
}
