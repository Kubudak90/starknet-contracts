// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DataTypes} from "../types/DataTypes.sol";

/// @title ICore
/// @notice Core AMM interface for pool and position management
interface ICore {
    // Events
    event PoolInitialized(
        DataTypes.PoolKey poolKey,
        int128 initialTick,
        uint256 sqrtRatio
    );

    event PositionUpdated(
        address indexed locker,
        DataTypes.PoolKey poolKey,
        DataTypes.UpdatePositionParameters params,
        DataTypes.Delta delta
    );

    event PositionFeesCollected(
        DataTypes.PoolKey poolKey,
        DataTypes.PositionKey positionKey,
        DataTypes.Delta delta
    );

    event Swapped(
        address indexed locker,
        DataTypes.PoolKey poolKey,
        DataTypes.SwapParameters params,
        DataTypes.Delta delta,
        uint256 sqrtRatioAfter,
        int128 tickAfter,
        uint128 liquidityAfter
    );

    event ProtocolFeesWithdrawn(
        address indexed recipient,
        address indexed token,
        uint128 amount
    );

    event ProtocolFeesPaid(
        DataTypes.PoolKey poolKey,
        DataTypes.PositionKey positionKey,
        DataTypes.Delta delta
    );

    event FeesAccumulated(
        DataTypes.PoolKey poolKey,
        uint128 amount0,
        uint128 amount1
    );

    event SavedBalance(
        DataTypes.SavedBalanceKey key,
        uint128 amount
    );

    event LoadedBalance(
        DataTypes.SavedBalanceKey key,
        uint128 amount
    );

    // View Functions
    function getProtocolFeesCollected(address token) external view returns (uint128);

    function getLockerState(uint32 id) external view returns (DataTypes.LockerState memory);

    function getLockerDelta(uint32 id, address token) external view returns (int256);

    function getPoolPrice(DataTypes.PoolKey calldata poolKey) external view returns (DataTypes.PoolPrice memory);

    function getPoolLiquidity(DataTypes.PoolKey calldata poolKey) external view returns (uint128);

    function getPoolFeesPerLiquidity(DataTypes.PoolKey calldata poolKey) external view returns (DataTypes.FeesPerLiquidity memory);

    function getPoolTickLiquidityDelta(DataTypes.PoolKey calldata poolKey, int128 tick) external view returns (int128);

    function getPoolTickLiquidityNet(DataTypes.PoolKey calldata poolKey, int128 tick) external view returns (uint128);

    function getPoolTickFeesOutside(DataTypes.PoolKey calldata poolKey, int128 tick) external view returns (DataTypes.FeesPerLiquidity memory);

    function getPosition(DataTypes.PoolKey calldata poolKey, DataTypes.PositionKey calldata positionKey) external view returns (DataTypes.Position memory);

    function getPositionWithFees(DataTypes.PoolKey calldata poolKey, DataTypes.PositionKey calldata positionKey) external view returns (DataTypes.GetPositionWithFeesResult memory);

    function getSavedBalance(DataTypes.SavedBalanceKey calldata key) external view returns (uint128);

    function nextInitializedTick(DataTypes.PoolKey calldata poolKey, int128 tick, uint128 skipAhead) external view returns (int128, bool);

    function prevInitializedTick(DataTypes.PoolKey calldata poolKey, int128 tick, uint128 skipAhead) external view returns (int128, bool);

    function getCallPoints(address extension) external view returns (DataTypes.CallPoints memory);

    // State-Changing Functions
    function lock(bytes calldata data) external returns (bytes memory);

    function forward(address to, bytes calldata data) external returns (bytes memory);

    function initializePool(DataTypes.PoolKey calldata poolKey, int128 initialTick) external returns (uint256);

    function maybeInitializePool(DataTypes.PoolKey calldata poolKey, int128 initialTick) external returns (bool initialized, uint256 sqrtRatio);

    function updatePosition(DataTypes.PoolKey calldata poolKey, DataTypes.UpdatePositionParameters calldata params) external returns (DataTypes.Delta memory);

    function collectFees(DataTypes.PoolKey calldata poolKey, bytes32 salt, DataTypes.Bounds calldata bounds) external returns (DataTypes.Delta memory);

    function swap(DataTypes.PoolKey calldata poolKey, DataTypes.SwapParameters calldata params) external returns (DataTypes.Delta memory);

    function withdraw(address token, address recipient, uint128 amount) external;

    function pay(address token) external;

    function save(DataTypes.SavedBalanceKey calldata key, uint128 amount) external returns (uint128);

    function load(address token, bytes32 salt, uint128 amount) external returns (uint128);

    function withdrawProtocolFees(address recipient, address token, uint128 amount) external;

    function withdrawAllProtocolFees(address recipient, address token) external returns (uint128);

    function accumulateAsFees(DataTypes.PoolKey calldata poolKey, uint128 amount0, uint128 amount1) external;

    function setCallPoints(DataTypes.CallPoints calldata callPoints) external;
}

/// @title ILocker
/// @notice Interface for contracts that can lock the Core contract
interface ILocker {
    /// @notice Called by Core.lock() to execute operations
    /// @param id Lock identifier
    /// @param data Callback data
    /// @return result Callback result
    function locked(uint32 id, bytes calldata data) external returns (bytes memory result);
}

/// @title IForwardee
/// @notice Interface for contracts that can receive forwarded lock calls
interface IForwardee {
    /// @notice Called when a lock is forwarded to this contract
    /// @param originalLocker The original locker address
    /// @param id Lock identifier
    /// @param data Callback data
    /// @return result Callback result
    function forwarded(address originalLocker, uint32 id, bytes calldata data) external returns (bytes memory result);
}

/// @title IExtension
/// @notice Interface for pool extensions
interface IExtension {
    function beforeInitializePool(address caller, DataTypes.PoolKey calldata poolKey, int128 initialTick) external;

    function afterInitializePool(address caller, DataTypes.PoolKey calldata poolKey, int128 initialTick) external;

    function beforeUpdatePosition(address caller, DataTypes.PoolKey calldata poolKey, DataTypes.UpdatePositionParameters calldata params) external;

    function afterUpdatePosition(address caller, DataTypes.PoolKey calldata poolKey, DataTypes.UpdatePositionParameters calldata params, DataTypes.Delta calldata delta) external;

    function beforeSwap(address caller, DataTypes.PoolKey calldata poolKey, DataTypes.SwapParameters calldata params) external;

    function afterSwap(address caller, DataTypes.PoolKey calldata poolKey, DataTypes.SwapParameters calldata params, DataTypes.Delta calldata delta) external;

    function beforeCollectFees(address caller, DataTypes.PoolKey calldata poolKey, bytes32 salt, DataTypes.Bounds calldata bounds) external;

    function afterCollectFees(address caller, DataTypes.PoolKey calldata poolKey, bytes32 salt, DataTypes.Bounds calldata bounds, DataTypes.Delta calldata delta) external;
}
