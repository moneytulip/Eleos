// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./IBorrowable.sol";
import "./IClaimable.sol";
import "./ISplitter.sol";
import "./IFeeDistributor.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./ISupplyVault.sol";

interface IFeeProcessor {
    function addBridgeToken(IERC20 token, IERC20 bridgeToken) external;

    function addDex(IUniswapV2Factory factory, uint256 swapFeeFactor) external;

    function removeDex(IUniswapV2Factory factory) external;

    function dexListLength() external view returns (uint256);

    function dexFactory(uint256 index) external view returns (IUniswapV2Factory);

    function dexSwapFeeFactor(uint256 index) external view returns (uint256);

    function setClaimable(ISplitter claimable) external;

    function setFeeDistributor(IFeeDistributor feeDistributor) external;

    function setReward(uint256 reward) external;

    function getReward(IBorrowable borrowable) external view returns (uint256);

    function getDefaultReward() external view returns (uint256);

    function addBorrowable(IBorrowable borrowable) external;

    function addBorrowableWithReward(IBorrowable borrowable, uint160 reward) external;

    function addBorrowables(IBorrowable[] calldata borrowableList) external;

    function updateBorrowable(IBorrowable borrowable, uint160 reward) external;

    function removeBorrowable(IBorrowable borrowable) external;

    function borrowableListLength() external view returns (uint256);

    function borrowableListItem(uint256 index) external view returns (IBorrowable);

    function borrowableEnabled(IBorrowable borrowable) external view returns (bool);

    function supplyVaultListLength() external view returns (uint256);

    function supplyVaultListItem(uint256 index) external view returns (ISupplyVault);

    function supplyVaultEnabled(ISupplyVault vault) external view returns (bool);

    function addSupplyVault(ISupplyVault vault) external;

    function addSupplyVaults(ISupplyVault[] calldata vault) external;

    function removeSupplyVault(ISupplyVault vault) external;

    function processSupplyVault(ISupplyVault vault) external;

    function processBorrowable(IBorrowable borrowable, address to) external;

    event SetClaimable(address indexed claimable);
    event SetFeeDistributor(address indexed feeDistributor);
    event SetReward(uint256 reward);
    event AddBorrowable(address indexed borrowable, uint256 reward);
    event UpdateBorrowable(address indexed borrowable, uint256 reward);
    event RemoveBorrowable(address indexed borrowable);
    event AddSupplyVault(address indexed vault);
    event RemoveSupplyVault(address indexed vault);
    event ProcessSupplyVault(address indexed caller, address indexed vault, uint256 share);
    event ProcessBorrowable(
        address indexed caller,
        address indexed borrowable,
        uint256 tarotAmount,
        uint256 rewardAmount
    );
}
