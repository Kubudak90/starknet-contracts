// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title DataTypes
/// @notice Core data structures for the Ekubo AMM protocol adapted for EVM
library DataTypes {
    /// @notice Uniquely identifies a pool
    /// @dev token0 must be < token1 (sorted by address)
    /// @param token0 The first token of the pool (smaller address)
    /// @param token1 The second token of the pool (larger address)
    /// @param fee Fee specified as a fixed point number (1% = 2^128 / 100)
    /// @param tickSpacing Minimum spacing between initialized ticks
    /// @param extension Address of a contract implementing additional pool functionality
    struct PoolKey {
        address token0;
        address token1;
        uint128 fee;
        uint128 tickSpacing;
        address extension;
    }

    /// @notice Uniquely identifies a position within a pool
    /// @param salt Random number to allow multiple positions with same pool and bounds
    /// @param owner Immutable address of the position owner
    /// @param bounds Price range where liquidity is active
    struct PositionKey {
        bytes32 salt;
        address owner;
        Bounds bounds;
    }

    /// @notice Tick bounds for a position (price range)
    /// @param lower Lower tick bound
    /// @param upper Upper tick bound
    struct Bounds {
        int128 lower;
        int128 upper;
    }

    /// @notice Token balance changes from the core contract's perspective
    /// @dev For example: swapping 100 token0 for 150 token1 = { amount0: 100, amount1: -150 }
    /// @param amount0 Change in token0 balance (positive = owed to pool, negative = owed to user)
    /// @param amount1 Change in token1 balance (positive = owed to pool, negative = owed to user)
    struct Delta {
        int256 amount0;
        int256 amount1;
    }

    /// @notice Saved balance key for deferred transfers
    /// @param owner Address that owns the saved balance
    /// @param token Address of the token
    /// @param salt Random number to allow separate saved balances
    struct SavedBalanceKey {
        address owner;
        address token;
        bytes32 salt;
    }

    /// @notice Pool price state
    /// @param sqrtRatio Current sqrt price ratio (Q64.96 format)
    /// @param tick Current tick
    struct PoolPrice {
        uint256 sqrtRatio;
        int128 tick;
    }

    /// @notice Position state
    /// @param liquidity Amount of liquidity in the position
    /// @param feesPerLiquidityInsideLast Snapshot of fees per liquidity at last update
    struct Position {
        uint128 liquidity;
        FeesPerLiquidity feesPerLiquidityInsideLast;
    }

    /// @notice Accumulated fees per unit of liquidity
    /// @param amount0 Accumulated fees in token0
    /// @param amount1 Accumulated fees in token1
    struct FeesPerLiquidity {
        uint256 amount0;
        uint256 amount1;
    }

    /// @notice Parameters for updating a position
    /// @param salt Position salt
    /// @param bounds Position price range
    /// @param liquidityDelta Amount of liquidity to add (positive) or remove (negative)
    struct UpdatePositionParameters {
        bytes32 salt;
        Bounds bounds;
        int128 liquidityDelta;
    }

    /// @notice Parameters for executing a swap
    /// @param amount Amount to swap (positive = exact input, negative = exact output)
    /// @param isToken1 True if swapping token0 for token1, false otherwise
    /// @param sqrtRatioLimit Price limit for the swap
    /// @param skipAhead Number of ticks to skip when searching for liquidity
    struct SwapParameters {
        int256 amount;
        bool isToken1;
        uint256 sqrtRatioLimit;
        uint128 skipAhead;
    }

    /// @notice Extension call points configuration
    /// @dev Bitmap indicating which hooks are enabled
    /// @param beforeInitializePool Called before pool initialization
    /// @param afterInitializePool Called after pool initialization
    /// @param beforeUpdatePosition Called before position update
    /// @param afterUpdatePosition Called after position update
    /// @param beforeSwap Called before swap
    /// @param afterSwap Called after swap
    /// @param beforeCollectFees Called before fee collection
    /// @param afterCollectFees Called after fee collection
    struct CallPoints {
        bool beforeInitializePool;
        bool afterInitializePool;
        bool beforeUpdatePosition;
        bool afterUpdatePosition;
        bool beforeSwap;
        bool afterSwap;
        bool beforeCollectFees;
        bool afterCollectFees;
    }

    /// @notice Locker state information
    /// @param locker Address currently holding the lock
    /// @param nonzeroDeltaCount Number of tokens with non-zero deltas
    struct LockerState {
        address locker;
        uint32 nonzeroDeltaCount;
    }

    /// @notice Result from getting position with fees
    /// @param position The position state
    /// @param fees0 Accumulated fees in token0
    /// @param fees1 Accumulated fees in token1
    /// @param feesPerLiquidityInsideCurrent Current fees per liquidity inside position bounds
    struct GetPositionWithFeesResult {
        Position position;
        uint128 fees0;
        uint128 fees1;
        FeesPerLiquidity feesPerLiquidityInsideCurrent;
    }
}
