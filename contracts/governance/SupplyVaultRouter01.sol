// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ISupplyVaultRouter01.sol";
import "../interfaces/IWETH.sol";
import "../libraries/TransferHelper.sol";

contract SupplyVaultRouter01 is ISupplyVaultRouter01 {
    using SafeERC20 for IERC20;
    using SafeERC20 for ISupplyVault;

    address immutable WETH;

    constructor(address _WETH) public {
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function _mintBorrowableAndEnter(ISupplyVault vault, IBorrowable toBorrowable) private returns (uint256 share) {
        uint256 borrowableAmount = toBorrowable.mint(address(this));
        IERC20(address(toBorrowable)).safeApprove(address(vault), borrowableAmount);
        share = vault.enterWithToken(address(toBorrowable), borrowableAmount);
        IERC20(address(vault)).safeTransfer(msg.sender, share);
    }

    function enter(
        ISupplyVault vault,
        uint256 underlyingAmount,
        IBorrowable toBorrowable
    ) external override checkBorrowable(vault, toBorrowable) returns (uint256 share) {
        IERC20 underlying = IERC20(toBorrowable.underlying());
        underlying.safeTransferFrom(msg.sender, address(toBorrowable), underlyingAmount);
        return _mintBorrowableAndEnter(vault, toBorrowable);
    }

    function enterETH(ISupplyVault vault, IBorrowable toBorrowable)
        external
        payable
        override
        checkETH(vault)
        checkBorrowable(vault, toBorrowable)
        returns (uint256 share)
    {
        IWETH(WETH).deposit{value: msg.value}();
        IERC20(WETH).safeTransfer(address(toBorrowable), msg.value);
        return _mintBorrowableAndEnter(vault, toBorrowable);
    }

    function _enterWithAlloc(ISupplyVault vault, uint256 underlyingAmount) private returns (uint256 share) {
        IERC20 underlying = vault.underlying();
        underlying.safeApprove(address(vault), underlyingAmount);
        share = vault.enter(underlyingAmount);
        IERC20(address(vault)).safeTransfer(msg.sender, share);
    }

    function enterWithAlloc(ISupplyVault vault, uint256 underlyingAmount) external override returns (uint256 share) {
        IERC20 underlying = vault.underlying();
        underlying.safeTransferFrom(msg.sender, address(this), underlyingAmount);
        return _enterWithAlloc(vault, underlyingAmount);
    }

    function enterWithAllocETH(ISupplyVault vault) external payable override checkETH(vault) returns (uint256 share) {
        IWETH(WETH).deposit{value: msg.value}();
        return _enterWithAlloc(vault, msg.value);
    }

    function enterWithToken(
        ISupplyVault vault,
        address token,
        uint256 tokenAmount
    ) external override returns (uint256 share) {
        IERC20(token).safeTransferFrom(msg.sender, address(this), tokenAmount);
        IERC20(token).safeApprove(address(vault), tokenAmount);
        share = vault.enterWithToken(token, tokenAmount);
        IERC20(address(vault)).safeTransfer(msg.sender, share);
    }

    function _leave(ISupplyVault vault, uint256 share) private returns (IERC20 underlying, uint256 underlyingAmount) {
        underlying = vault.underlying();
        IERC20(address(vault)).safeTransferFrom(msg.sender, address(this), share);
        underlyingAmount = vault.leave(share);
    }

    function leave(ISupplyVault vault, uint256 share) external override returns (uint256 underlyingAmount) {
        IERC20 underlying;
        (underlying, underlyingAmount) = _leave(vault, share);
        underlying.safeTransfer(msg.sender, underlyingAmount);
    }

    function leaveETH(ISupplyVault vault, uint256 share)
        external
        override
        checkETH(vault)
        returns (uint256 underlyingAmount)
    {
        IERC20 underlying;
        (underlying, underlyingAmount) = _leave(vault, share);
        IWETH(WETH).withdraw(underlyingAmount);
        TransferHelper.safeTransferETH(msg.sender, underlyingAmount);
    }

    modifier checkETH(ISupplyVault vault) {
        require(WETH == address(vault.underlying()), "SVR: NOT_WETH");
        _;
    }

    modifier checkBorrowable(ISupplyVault vault, IBorrowable borrowable) {
        require(address(vault.underlying()) == borrowable.underlying(), "SVR: WRONG_BORROWABLE");
        _;
    }
}
