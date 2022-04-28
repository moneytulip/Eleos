pragma solidity =0.8.9;
//IERC20?
interface IImx {
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
}