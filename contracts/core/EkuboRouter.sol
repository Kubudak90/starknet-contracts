// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DataTypes} from "../types/DataTypes.sol";
import {ICore, ILocker} from "../interfaces/ICore.sol";
import {TickMath} from "../libraries/TickMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title EkuboRouter
/// @notice Multi-hop swap router for Ekubo AMM
contract EkuboRouter is ILocker {
    ICore public immutable core;

    struct RouteNode {
        DataTypes.PoolKey poolKey;
        uint256 sqrtRatioLimit;
        uint128 skipAhead;
    }

    struct TokenAmount {
        address token;
        int256 amount;
    }

    struct Swap {
        RouteNode[] route;
        TokenAmount tokenAmount;
    }

    enum CallbackType {
        Swap,
        MultiSwap,
        Quote
    }

    struct SwapCallbackData {
        Swap[] swaps;
        bool simulate;
    }

    constructor(address _core) {
        core = ICore(_core);
    }

    /// @notice Execute a single-hop swap
    function swap(
        RouteNode calldata node,
        TokenAmount calldata tokenAmount
    ) external returns (DataTypes.Delta memory) {
        RouteNode[] memory route = new RouteNode[](1);
        route[0] = node;

        Swap memory swapData = Swap({
            route: route,
            tokenAmount: tokenAmount
        });

        Swap[] memory swaps = new Swap[](1);
        swaps[0] = swapData;

        DataTypes.Delta[] memory deltas = _executeSwaps(swaps, false);
        return deltas[0];
    }

    /// @notice Execute a multi-hop swap
    function multihopSwap(
        RouteNode[] calldata route,
        TokenAmount calldata tokenAmount
    ) external returns (DataTypes.Delta[] memory) {
        Swap memory swapData = Swap({
            route: route,
            tokenAmount: tokenAmount
        });

        Swap[] memory swaps = new Swap[](1);
        swaps[0] = swapData;

        return _executeSwaps(swaps, false);
    }

    /// @notice Execute multiple multi-hop swaps
    function multiMultihopSwap(
        Swap[] calldata swaps
    ) external returns (DataTypes.Delta[][] memory) {
        DataTypes.Delta[] memory flatDeltas = _executeSwaps(swaps, false);

        DataTypes.Delta[][] memory result = new DataTypes.Delta[][](swaps.length);
        uint256 index = 0;

        for (uint256 i = 0; i < swaps.length; i++) {
            result[i] = new DataTypes.Delta[](swaps[i].route.length);
            for (uint256 j = 0; j < swaps[i].route.length; j++) {
                result[i][j] = flatDeltas[index++];
            }
        }

        return result;
    }

    /// @notice Quote a single swap without executing
    function quoteSwap(
        RouteNode calldata node,
        TokenAmount calldata tokenAmount
    ) external returns (DataTypes.Delta memory) {
        RouteNode[] memory route = new RouteNode[](1);
        route[0] = node;

        Swap memory swapData = Swap({
            route: route,
            tokenAmount: tokenAmount
        });

        Swap[] memory swaps = new Swap[](1);
        swaps[0] = swapData;

        DataTypes.Delta[] memory deltas = _executeSwaps(swaps, true);
        return deltas[0];
    }

    /// @notice Quote a multi-hop swap without executing
    function quoteMultihopSwap(
        RouteNode[] calldata route,
        TokenAmount calldata tokenAmount
    ) external returns (DataTypes.Delta[] memory) {
        Swap memory swapData = Swap({
            route: route,
            tokenAmount: tokenAmount
        });

        Swap[] memory swaps = new Swap[](1);
        swaps[0] = swapData;

        return _executeSwaps(swaps, true);
    }

    /// @notice Get the delta required to swap a pool to a target sqrt ratio
    /// @param poolKey The pool to query
    /// @param sqrtRatio The target sqrt ratio
    /// @return delta The amount delta required to reach the target price
    function getDeltaToSqrtRatio(
        DataTypes.PoolKey calldata poolKey,
        uint256 sqrtRatio
    ) external returns (DataTypes.Delta memory delta) {
        // Get current pool price
        DataTypes.PoolPrice memory currentPrice = core.getPoolPrice(poolKey);

        // Calculate skip ahead
        int128 tickDiff = currentPrice.tick - TickMath.sqrtRatioToTick(sqrtRatio);
        uint128 tickDiffMag = tickDiff >= 0 ? uint128(tickDiff) : uint128(-tickDiff);
        uint128 skipAhead = tickDiffMag / (poolKey.tickSpacing * 127);

        // Create swap parameters with max amount
        RouteNode memory node = RouteNode({
            poolKey: poolKey,
            sqrtRatioLimit: sqrtRatio,
            skipAhead: skipAhead
        });

        TokenAmount memory tokenAmount = TokenAmount({
            token: sqrtRatio <= currentPrice.sqrtRatio ? poolKey.token1 : poolKey.token0,
            amount: type(int256).min // Max negative amount
        });

        // Execute the swap and return delta
        return swap(node, tokenAmount);
    }

    /// @notice Get market depth at current price
    /// @param poolKey The pool to query
    /// @param sqrtPercent The percent range to check (as sqrt)
    /// @return token0Depth Depth in token0 direction
    /// @return token1Depth Depth in token1 direction
    function getMarketDepth(
        DataTypes.PoolKey calldata poolKey,
        uint128 sqrtPercent
    ) external returns (uint128 token0Depth, uint128 token1Depth) {
        // Convert sqrt percent to 64x64 fixed point
        // p_plus_one = u256 { high: 1, low: sqrt_percent }
        uint256 pPlusOne = (uint256(1) << 128) | uint256(sqrtPercent);

        // percent_64x64 = (pPlusOne * pPlusOne) / (2^256 / 2^64) - 2^64
        uint256 denomForPercent = 0x1000000000000000000000000000000000000000000000000; // 2^192
        uint256 percent64x64PlusOne = (pPlusOne * pPlusOne) / denomForPercent;
        uint128 percent64x64 = uint128(percent64x64PlusOne - 0x10000000000000000);

        // Get current pool price
        DataTypes.PoolPrice memory currentPrice = core.getPoolPrice(poolKey);

        return getMarketDepthAtSqrtRatio(poolKey, currentPrice.sqrtRatio, percent64x64);
    }

    /// @notice Get market depth at a specific sqrt ratio
    /// @param poolKey The pool to query
    /// @param sqrtRatio The starting sqrt ratio
    /// @param percent64x64 The percent range in 64x64 fixed point
    /// @return token0Depth Depth in token0 direction (price going down)
    /// @return token1Depth Depth in token1 direction (price going up)
    function getMarketDepthAtSqrtRatio(
        DataTypes.PoolKey calldata poolKey,
        uint256 sqrtRatio,
        uint128 percent64x64
    ) external returns (uint128 token0Depth, uint128 token1Depth) {
        // Calculate sqrt_percent from percent_64x64
        uint256 sqrt_percent = _sqrt((0x100000000000000000000000000000000 + (uint256(percent64x64) * 0x10000000000000000))) - 0x10000000000000000;

        // 2^64 as 1.64 fixed point
        uint256 denom = 0x10000000000000000;
        uint256 num = denom + sqrt_percent;

        DataTypes.PoolPrice memory currentPoolPrice = core.getPoolPrice(poolKey);

        // Swap to the specified starting price if needed
        if (currentPoolPrice.sqrtRatio != sqrtRatio) {
            int128 tickStart = TickMath.sqrtRatioToTick(sqrtRatio);
            int128 tickDiff = currentPoolPrice.tick - tickStart;
            uint128 tickDiffMag = tickDiff >= 0 ? uint128(tickDiff) : uint128(-tickDiff);

            core.swap(
                poolKey,
                DataTypes.SwapParameters({
                    amount: type(int256).min, // Max negative amount
                    isToken1: sqrtRatio < currentPoolPrice.sqrtRatio,
                    sqrtRatioLimit: sqrtRatio,
                    skipAhead: tickDiffMag / (poolKey.tickSpacing * 127)
                })
            );

            currentPoolPrice.sqrtRatio = sqrtRatio;
            currentPoolPrice.tick = tickStart;
        }

        // Calculate price bounds
        uint256 priceHigh = _min(
            _mulDiv(currentPoolPrice.sqrtRatio, num, denom),
            TickMath.MAX_SQRT_RATIO
        );
        uint256 priceLow = _max(
            _mulDivRoundUp(currentPoolPrice.sqrtRatio, denom, num),
            TickMath.MIN_SQRT_RATIO
        );

        // Calculate skip ahead for downward direction
        int128 tickLow = TickMath.sqrtRatioToTick(priceLow);
        int128 skipTickDiff = currentPoolPrice.tick - tickLow;
        uint128 skipTickDiffMag = skipTickDiff >= 0 ? uint128(skipTickDiff) : uint128(-skipTickDiff);
        uint128 skipAhead = skipTickDiffMag / (poolKey.tickSpacing * 127);

        // Swap upward to price_high
        DataTypes.Delta memory deltaHigh;
        if (currentPoolPrice.sqrtRatio != priceHigh) {
            deltaHigh = core.swap(
                poolKey,
                DataTypes.SwapParameters({
                    amount: type(int256).min,
                    isToken1: false,
                    sqrtRatioLimit: priceHigh,
                    skipAhead: skipAhead
                })
            );
        }

        // Swap back to starting price
        if (currentPoolPrice.sqrtRatio != priceHigh) {
            core.swap(
                poolKey,
                DataTypes.SwapParameters({
                    amount: type(int256).min,
                    isToken1: true,
                    sqrtRatioLimit: currentPoolPrice.sqrtRatio,
                    skipAhead: skipAhead
                })
            );
        }

        // Swap downward to price_low
        DataTypes.Delta memory deltaLow;
        if (currentPoolPrice.sqrtRatio != priceLow) {
            deltaLow = core.swap(
                poolKey,
                DataTypes.SwapParameters({
                    amount: type(int256).min,
                    isToken1: true,
                    sqrtRatioLimit: priceLow,
                    skipAhead: skipAhead
                })
            );
        }

        // Return the magnitudes
        token0Depth = deltaHigh.amount0 >= 0 ? uint128(uint256(deltaHigh.amount0)) : uint128(uint256(-deltaHigh.amount0));
        token1Depth = deltaLow.amount1 >= 0 ? uint128(uint256(deltaLow.amount1)) : uint128(uint256(-deltaLow.amount1));
    }

    /// @notice Callback from Core.lock()
    function locked(uint32, bytes calldata data) external override returns (bytes memory) {
        require(msg.sender == address(core), "Only core");

        (CallbackType callbackType, bytes memory callbackData) = abi.decode(data, (CallbackType, bytes));

        if (callbackType == CallbackType.Swap || callbackType == CallbackType.MultiSwap) {
            return _handleSwaps(callbackData);
        } else if (callbackType == CallbackType.Quote) {
            return _handleQuote(callbackData);
        }

        revert("Unknown callback type");
    }

    function _executeSwaps(
        Swap[] memory swaps,
        bool simulate
    ) internal returns (DataTypes.Delta[] memory) {
        bytes memory data = abi.encode(
            simulate ? CallbackType.Quote : CallbackType.MultiSwap,
            SwapCallbackData({
                swaps: swaps,
                simulate: simulate
            })
        );

        bytes memory result = core.lock(data);
        return abi.decode(result, (DataTypes.Delta[]));
    }

    function _handleSwaps(bytes memory data) internal returns (bytes memory) {
        SwapCallbackData memory params = abi.decode(data, (SwapCallbackData));

        uint256 totalSwaps = 0;
        for (uint256 i = 0; i < params.swaps.length; i++) {
            totalSwaps += params.swaps[i].route.length;
        }

        DataTypes.Delta[] memory allDeltas = new DataTypes.Delta[](totalSwaps);
        uint256 deltaIndex = 0;

        for (uint256 i = 0; i < params.swaps.length; i++) {
            Swap memory swapData = params.swaps[i];
            TokenAmount memory currentTokenAmount = swapData.tokenAmount;

            DataTypes.Delta memory firstDelta;
            DataTypes.PoolKey memory firstPoolKey;
            bool firstSwap = true;

            for (uint256 j = 0; j < swapData.route.length; j++) {
                RouteNode memory node = swapData.route[j];

                bool isToken1 = currentTokenAmount.token == node.poolKey.token1;

                uint256 sqrtRatioLimit = node.sqrtRatioLimit;
                if (sqrtRatioLimit == 0) {
                    sqrtRatioLimit = _isPriceIncreasing(currentTokenAmount.amount > 0, isToken1)
                        ? TickMath.MAX_SQRT_RATIO
                        : TickMath.MIN_SQRT_RATIO;
                }

                DataTypes.Delta memory delta = core.swap(
                    node.poolKey,
                    DataTypes.SwapParameters({
                        amount: currentTokenAmount.amount,
                        isToken1: isToken1,
                        sqrtRatioLimit: sqrtRatioLimit,
                        skipAhead: node.skipAhead
                    })
                );

                allDeltas[deltaIndex++] = delta;

                if (firstSwap) {
                    firstDelta = delta;
                    firstPoolKey = node.poolKey;
                    firstSwap = false;
                }

                // Update token amount for next hop
                currentTokenAmount = TokenAmount({
                    token: isToken1 ? node.poolKey.token0 : node.poolKey.token1,
                    amount: isToken1 ? -delta.amount0 : -delta.amount1
                });
            }

            // Handle token transfers if not simulating
            if (!params.simulate) {
                _handleTokenTransfers(
                    currentTokenAmount,
                    firstDelta,
                    swapData.tokenAmount.token,
                    firstPoolKey
                );
            }
        }

        return abi.encode(allDeltas);
    }

    function _handleQuote(bytes memory data) internal returns (bytes memory) {
        // Quote is handled the same as swap but with simulate=true
        return _handleSwaps(data);
    }

    function _handleTokenTransfers(
        TokenAmount memory finalTokenAmount,
        DataTypes.Delta memory firstDelta,
        address firstToken,
        DataTypes.PoolKey memory firstPoolKey
    ) internal {
        // Withdraw the output tokens
        if (finalTokenAmount.amount < 0) {
            core.withdraw(
                finalTokenAmount.token,
                address(this),
                uint128(uint256(-finalTokenAmount.amount))
            );
        }

        // Pay the input tokens - determine which delta to use based on first token
        int256 firstAmount;
        if (firstToken == firstPoolKey.token0) {
            firstAmount = firstDelta.amount0;
        } else if (firstToken == firstPoolKey.token1) {
            firstAmount = firstDelta.amount1;
        } else {
            revert("First token not in first pool");
        }

        if (firstAmount > 0) {
            IERC20(firstToken).approve(address(core), uint256(firstAmount));
            core.pay(firstToken);
        }
    }

    function _isPriceIncreasing(bool amountPositive, bool isToken1) internal pure returns (bool) {
        return amountPositive == isToken1;
    }

    /// @notice Calculate square root using Babylonian method
    function _sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;

        uint256 z = (x + 1) / 2;
        uint256 y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }

        return y;
    }

    /// @notice Multiply and divide with rounding down
    function _mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256) {
        uint256 result = (a * b) / denominator;
        return result;
    }

    /// @notice Multiply and divide with rounding up
    function _mulDivRoundUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256) {
        uint256 result = (a * b);
        uint256 remainder = result % denominator;
        result = result / denominator;

        if (remainder > 0) {
            result += 1;
        }

        return result;
    }

    /// @notice Return minimum of two values
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Return maximum of two values
    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}
