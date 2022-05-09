// SPDX-License-Identifier: MIT-License
pragma solidity =0.8.9;

import "../../contracts/AmplifyERC20.sol";

contract AmplifyERC20Harness is AmplifyERC20 {
    constructor(string memory _name, string memory _symbol)
        public
        AmplifyERC20()
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
