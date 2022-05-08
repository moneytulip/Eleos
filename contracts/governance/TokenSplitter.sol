// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/ITokenSplitter.sol";

// This contract handles weighted forwarding received ERC20 tokens to two addresses
contract TokenSplitter is Ownable, ReentrancyGuard, ITokenSplitter {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 constant MAX_WEIGHT = 100e16; // 100%

    // Fraction of received tokens that will go to left address
    uint256 m_weight;

    // Address that will receive (weight / 1e18) share of received tokens
    address m_left;
    // Address that will receive (1 - (weight / 1e18)) share of received tokens
    address m_right;

    // List of ERC20 tokens that will be handled
    address[] m_tokenList;
    // Map of ERC20 tokens that will be handled
    mapping(address => bool) m_tokenEnabledMap;
    // Map of ERC20 tokens that have a custom weight
    mapping(address => bool) m_tokenHasCustomWeightMap;
    // Map of custom weights
    mapping(address => uint256) m_tokenCustomWeightMap;

    constructor(
        uint256 weight,
        address left,
        address right,
        address[] memory tokenList
    ) public {
        updateSplit(weight, left, right);
        for (uint256 i = 0; i < tokenList.length; i++) {
            _addToken(tokenList[i], false, 0);
        }
    }

    receive() external payable {
        require(false, "TokenSplitter: Should not receieve ETH");
    }

    function getWeight() external view override returns (uint256) {
        return m_weight;
    }

    function getLeft() external view override returns (address) {
        return m_left;
    }

    function getRight() external view override returns (address) {
        return m_right;
    }

    function getTokenListLength() external view override returns (uint256) {
        return m_tokenList.length;
    }

    function getToken(uint256 index) external view override returns (address) {
        require(index < m_tokenList.length, "TokenSplitter: Token index out of bounds");
        return m_tokenList[index];
    }

    function getTokenEnabled(address token) external view override returns (bool) {
        return m_tokenEnabledMap[token];
    }

    function getTokenHasCustomWeight(address token) external view override _checkTokenEnabled(token) returns (bool) {
        return m_tokenHasCustomWeightMap[token];
    }

    function getTokenWeight(address token) external view override _checkTokenEnabled(token) returns (uint256) {
        return _getTokenWeight(token, m_weight);
    }

    // Internal function to transfer balances of a token to left and right per a given weighting.
    // The caller must ensure to only call this on validated tokens with a balance
    function _splitTransfer(address token, uint256 tokenWeight)
        private
        nonReentrant
        returns (uint256 leftAmount, uint256 rightAmount)
    {
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        if (tokenBalance == 0) {
            return (leftAmount = 0, rightAmount = 0);
        }
        leftAmount = tokenBalance.mul(tokenWeight).div(MAX_WEIGHT);
        if (leftAmount > 0) {
            IERC20(token).safeTransfer(m_left, leftAmount);
        }
        // We check the remaining balance to handle exchange rates and transfer taxes
        rightAmount = IERC20(token).balanceOf(address(this));
        if (rightAmount > 0) {
            IERC20(token).safeTransfer(m_right, rightAmount);
        }

        emit SplitTransfer(token, leftAmount, rightAmount);
    }

    function claim(address token) external override _checkTokenEnabled(token) {
        uint256 tokenWeight = _getTokenWeight(token, m_weight);
        _splitTransfer(token, tokenWeight);
    }

    function claimMany(address[] calldata tokenList) external override {
        uint256 defaultWeight = m_weight; // gas savings

        for (uint256 i = 0; i < tokenList.length; i++) {
            address token = tokenList[i];
            require(m_tokenEnabledMap[token], "TokenSplitter: Token must be enabled");

            uint256 tokenWeight = _getTokenWeight(token, defaultWeight);
            _splitTransfer(token, tokenWeight);
        }
    }

    function claimAll() external override {
        uint256 defaultWeight = m_weight; // gas savings

        for (uint256 i = 0; i < m_tokenList.length; i++) {
            address token = m_tokenList[i];

            uint256 tokenWeight = _getTokenWeight(token, defaultWeight);
            _splitTransfer(token, tokenWeight);
        }
    }

    function updateSplit(
        uint256 weight,
        address left,
        address right
    ) public override onlyOwner _checkWeight(weight) {
        m_weight = weight;
        m_left = left;
        m_right = right;

        emit SplitUpdated(weight, left, right);
    }

    function addToken(address token) external override onlyOwner {
        _addToken(token, false, 0);
    }

    function addTokens(address[] calldata tokenList) external override onlyOwner {
        for (uint256 i = 0; i < tokenList.length; i++) {
            _addToken(tokenList[i], false, 0);
        }
    }

    function addTokenWithCustomWeight(address token, uint256 tokenWeight)
        public
        override
        onlyOwner
        _checkWeight(tokenWeight)
    {
        _addToken(token, true, tokenWeight);
    }

    function _addToken(
        address token,
        bool hasCustomWeight,
        uint256 weight
    ) private _checkTokenNotEnabled(token) {
        m_tokenList.push(token);
        m_tokenEnabledMap[token] = true;
        if (hasCustomWeight) {
            m_tokenHasCustomWeightMap[token] = true;
            m_tokenCustomWeightMap[token] = weight;
        }

        emit TokenAdded(token, hasCustomWeight, weight);
    }

    function _updateToken(
        address token,
        bool hasCustomWeight,
        uint256 tokenWeight
    ) private {
        if (hasCustomWeight) {
            m_tokenHasCustomWeightMap[token] = true;
            m_tokenCustomWeightMap[token] = tokenWeight;
        } else {
            delete m_tokenHasCustomWeightMap[token];
            delete m_tokenCustomWeightMap[token];
        }

        emit TokenUpdated(token, hasCustomWeight, tokenWeight);
    }

    function updateTokenUseDefaultWeight(address token) external override onlyOwner _checkTokenEnabled(token) {
        _updateToken(token, false, 0);
    }

    function updateTokenUseCustomWeight(address token, uint256 tokenWeight)
        external
        override
        onlyOwner
        _checkTokenEnabled(token)
        _checkWeight(tokenWeight)
    {
        _updateToken(token, true, tokenWeight);
    }

    function removeToken(address token) external override onlyOwner _checkTokenEnabled(token) {
        uint256 index = _indexOfToken(token);

        address last = m_tokenList[m_tokenList.length - 1];
        // Move the last element into our removed slot:
        m_tokenList[index] = last;
        // Discard the last element:
        m_tokenList.pop();
        // Remove token from maps:
        delete m_tokenEnabledMap[token];
        delete m_tokenHasCustomWeightMap[token];
        delete m_tokenCustomWeightMap[token];

        emit TokenRemoved(token);
    }

    modifier _checkTokenEnabled(address token) {
        require(m_tokenEnabledMap[token], "TokenSplitter: Token must be enabled");
        _;
    }

    modifier _checkTokenNotEnabled(address token) {
        require(!m_tokenEnabledMap[token], "TokenSplitter: Token must not be enabled");
        _;
    }

    modifier _checkWeight(uint256 weight) {
        require(weight <= MAX_WEIGHT, "TokenSplitter: Weight out of range");
        _;
    }

    function _indexOfToken(address token) private view returns (uint256 index) {
        for (uint256 i = 0; i < m_tokenList.length; i++) {
            if (m_tokenList[i] == token) {
                return (index = i);
            }
        }
        // We should never get here because this function should only be called with enabled tokens
        assert(false);
    }

    function _getTokenWeight(address token, uint256 defaultWeight) private view returns (uint256) {
        if (m_tokenHasCustomWeightMap[token]) {
            // Token has a custom weight so use that
            return m_tokenCustomWeightMap[token];
        }
        // Use the default weight
        return defaultWeight;
    }
}
