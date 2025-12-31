// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LiquidityMath} from "./LiquidityMath.sol";

/// @title SqrtPriceMath
/// @notice Math for computing sqrt price ratios and token amounts
library SqrtPriceMath {
    /// @notice Get the next sqrt price from a delta of token0
    /// @param sqrtRatio Current sqrt price
    /// @param liquidity Available liquidity
    /// @param amount Amount of token0 (positive = adding to pool, negative = removing from pool)
    /// @return success True if calculation succeeded
    /// @return sqrtRatioNext Next sqrt price
    function getNextSqrtPriceFromAmount0(
        uint256 sqrtRatio,
        uint128 liquidity,
        int256 amount
    ) internal pure returns (bool success, uint256 sqrtRatioNext) {
        if (amount == 0) {
            return (true, sqrtRatio);
        }

        require(liquidity > 0, "NO_LIQUIDITY");

        uint256 numerator1 = uint256(liquidity) << 128;

        if (amount < 0) {
            // Taking out token0, giving token1, price goes up
            uint256 amountAbs = uint256(-amount);
            uint256 product;

            unchecked {
                product = amountAbs * sqrtRatio;
                // Check for overflow
                if (product / amountAbs != sqrtRatio) {
                    return (false, 0);
                }
            }

            if (numerator1 <= product) {
                return (false, 0);
            }

            uint256 denominator = numerator1 - product;
            if (denominator == 0) {
                return (false, 0);
            }

            sqrtRatioNext = LiquidityMath.mulDivRoundingUp(numerator1, sqrtRatio, denominator);
            return (true, sqrtRatioNext);
        } else {
            // Adding token0, taking token1, price goes down
            uint256 amountAbs = uint256(amount);
            uint256 denominator = (numerator1 / sqrtRatio) + amountAbs;

            sqrtRatioNext = numerator1 / denominator;
            if (numerator1 % denominator != 0) {
                sqrtRatioNext += 1;
            }

            return (true, sqrtRatioNext);
        }
    }

    /// @notice Get the next sqrt price from a delta of token1
    /// @param sqrtRatio Current sqrt price
    /// @param liquidity Available liquidity
    /// @param amount Amount of token1 (positive = adding to pool, negative = removing from pool)
    /// @return success True if calculation succeeded
    /// @return sqrtRatioNext Next sqrt price
    function getNextSqrtPriceFromAmount1(
        uint256 sqrtRatio,
        uint128 liquidity,
        int256 amount
    ) internal pure returns (bool success, uint256 sqrtRatioNext) {
        if (amount == 0) {
            return (true, sqrtRatio);
        }

        require(liquidity > 0, "NO_LIQUIDITY");

        uint256 amountAbs = amount < 0 ? uint256(-amount) : uint256(amount);
        uint256 quotient = (amountAbs << 128) / uint256(liquidity);

        if (amount < 0) {
            // Taking out token1, giving token0, price goes down
            if (sqrtRatio <= quotient) {
                return (false, 0);
            }

            sqrtRatioNext = sqrtRatio - quotient;

            // Adjust for rounding
            uint256 remainder = (amountAbs << 128) % uint256(liquidity);
            if (remainder != 0) {
                if (sqrtRatioNext == 0) {
                    return (false, 0);
                }
                sqrtRatioNext -= 1;
            }

            return (true, sqrtRatioNext);
        } else {
            // Adding token1, taking token0, price goes up
            unchecked {
                sqrtRatioNext = sqrtRatio + quotient;
                // Check for overflow
                if (sqrtRatioNext < sqrtRatio) {
                    return (false, 0);
                }
            }

            return (true, sqrtRatioNext);
        }
    }

    /// @notice Get amount0 delta between two sqrt prices
    /// @param sqrtRatioA First sqrt price
    /// @param sqrtRatioB Second sqrt price
    /// @param liquidity Liquidity
    /// @param roundUp Whether to round up
    /// @return amount0 Amount of token0
    function getAmount0Delta(
        uint256 sqrtRatioA,
        uint256 sqrtRatioB,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint128 amount0) {
        if (sqrtRatioA > sqrtRatioB) {
            (sqrtRatioA, sqrtRatioB) = (sqrtRatioB, sqrtRatioA);
        }

        require(sqrtRatioA > 0, "NONZERO");

        if (liquidity == 0 || sqrtRatioA == sqrtRatioB) {
            return 0;
        }

        uint256 numerator1 = uint256(liquidity) << 128;
        uint256 numerator2 = sqrtRatioB - sqrtRatioA;

        uint256 result = roundUp
            ? LiquidityMath.mulDivRoundingUp(
                LiquidityMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioB),
                1,
                sqrtRatioA
            )
            : LiquidityMath.mulDiv(
                LiquidityMath.mulDiv(numerator1, numerator2, sqrtRatioB),
                1,
                sqrtRatioA
            );

        require(result <= type(uint128).max, "OVERFLOW_AMOUNT0");
        amount0 = uint128(result);
    }

    /// @notice Get amount1 delta between two sqrt prices
    /// @param sqrtRatioA First sqrt price
    /// @param sqrtRatioB Second sqrt price
    /// @param liquidity Liquidity
    /// @param roundUp Whether to round up
    /// @return amount1 Amount of token1
    function getAmount1Delta(
        uint256 sqrtRatioA,
        uint256 sqrtRatioB,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint128 amount1) {
        if (sqrtRatioA > sqrtRatioB) {
            (sqrtRatioA, sqrtRatioB) = (sqrtRatioB, sqrtRatioA);
        }

        require(sqrtRatioA > 0, "NONZERO");

        if (liquidity == 0 || sqrtRatioA == sqrtRatioB) {
            return 0;
        }

        uint256 result = (sqrtRatioB - sqrtRatioA) * uint256(liquidity);

        if (roundUp) {
            // Round up: add 1 if there would be truncation
            result = (result >> 128) + ((result & ((1 << 128) - 1)) == 0 ? 0 : 1);
        } else {
            result = result >> 128;
        }

        require(result <= type(uint128).max, "OVERFLOW_AMOUNT1");
        amount1 = uint128(result);
    }
}
