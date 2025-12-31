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

    /// @notice Get market depth at a specific price range
    function getMarketDepth(
        DataTypes.PoolKey calldata poolKey,
        uint256 sqrtRatio,
        uint128 percentBps
    ) external view returns (uint128 token0Depth, uint128 token1Depth) {
        // Simplified depth calculation
        // Full implementation would query pool state and calculate liquidity depth
        return (0, 0);
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
                    swapData.tokenAmount.token
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
        address firstToken
    ) internal {
        // Withdraw the output tokens
        if (finalTokenAmount.amount < 0) {
            core.withdraw(
                finalTokenAmount.token,
                address(this),
                uint128(uint256(-finalTokenAmount.amount))
            );
        }

        // Pay the input tokens
        // TODO: This needs proper logic to determine which delta (amount0 or amount1) to use
        // based on whether firstToken matches token0 or token1 in the first pool
        // For now, we use amount0 as a placeholder
        int256 firstAmount = firstDelta.amount0;

        if (firstAmount > 0) {
            IERC20(firstToken).approve(address(core), uint256(firstAmount));
            core.pay(firstToken);
        }
    }

    function _isPriceIncreasing(bool amountPositive, bool isToken1) internal pure returns (bool) {
        return amountPositive == isToken1;
    }
}
