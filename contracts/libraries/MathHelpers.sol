pragma solidity 0.8.9;

library MathHelpers {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) {
            return a;
        }
        return b;
    }

    function min(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return min(a, min(b, c));
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a;
        }
        return b;
    }

    function max(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return max(a, max(b, c));
    }
}
