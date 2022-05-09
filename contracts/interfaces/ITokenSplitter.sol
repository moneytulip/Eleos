// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ISplitter.sol";

interface ITokenSplitter is ISplitter {
    event SplitUpdated(uint256 weight, address indexed left, address indexed right);
    event TokenAdded(address indexed token, bool hasCustomWeight, uint256 weight);
    event TokenUpdated(address indexed token, bool hasCustomWeight, uint256 weight);
    event TokenRemoved(address indexed token);
    event SplitTransfer(address indexed token, uint256 amountLeft, uint256 amountRight);

    function getWeight() external view returns (uint256);

    function getLeft() external view returns (address);

    function getRight() external view returns (address);

    function getTokenListLength() external view returns (uint256);

    function getToken(uint256 index) external view returns (address);

    function getTokenEnabled(address token) external view returns (bool);

    function getTokenHasCustomWeight(address token) external view returns (bool);

    function getTokenWeight(address token) external view returns (uint256);

    function claimMany(address[] calldata tokenList) external;

    function claimAll() external;

    function updateSplit(
        uint256 weight,
        address left,
        address right
    ) external;

    function addToken(address token) external;

    function addTokens(address[] calldata tokenList) external;

    function addTokenWithCustomWeight(address token, uint256 weight) external;

    function updateTokenUseDefaultWeight(address token) external;

    function updateTokenUseCustomWeight(address token, uint256 tokenWeight) external;

    function removeToken(address token) external;
}
