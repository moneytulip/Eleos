pragma solidity >=0.5.0;

interface IEleosCallee {
    function eleosBorrow(
        address sender,
        address borrower,
        uint256 borrowAmount,
        bytes calldata data
    ) external;

    function eleosRedeem(
        address sender,
        uint256 redeemAmount,
        bytes calldata data
    ) external;
}
