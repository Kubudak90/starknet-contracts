// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title LiquidityMath
/// @notice Math functions for liquidity calculations
library LiquidityMath {
    /// @notice Calculates token amount deltas from a liquidity delta
    /// @param sqrtRatio Current sqrt price ratio
    /// @param liquidityDelta Amount of liquidity to add or remove
    /// @param sqrtRatioLower Lower sqrt price ratio bound
    /// @param sqrtRatioUpper Upper sqrt price ratio bound
    /// @return amount0 Change in token0 amount
    /// @return amount1 Change in token1 amount
    function liquidityDeltaToAmountDelta(
        uint256 sqrtRatio,
        int128 liquidityDelta,
        uint256 sqrtRatioLower,
        uint256 sqrtRatioUpper
    ) internal pure returns (int256 amount0, int256 amount1) {
        require(sqrtRatioLower < sqrtRatioUpper, "Invalid bounds");

        if (liquidityDelta == 0) {
            return (0, 0);
        }

        if (sqrtRatio <= sqrtRatioLower) {
            // Current price below range - only token0 needed
            amount0 = getAmount0Delta(sqrtRatioLower, sqrtRatioUpper, liquidityDelta);
            amount1 = 0;
        } else if (sqrtRatio < sqrtRatioUpper) {
            // Current price within range - both tokens needed
            amount0 = getAmount0Delta(sqrtRatio, sqrtRatioUpper, liquidityDelta);
            amount1 = getAmount1Delta(sqrtRatioLower, sqrtRatio, liquidityDelta);
        } else {
            // Current price above range - only token1 needed
            amount0 = 0;
            amount1 = getAmount1Delta(sqrtRatioLower, sqrtRatioUpper, liquidityDelta);
        }
    }

    /// @notice Calculates the amount0 delta for a liquidity delta
    /// @param sqrtRatioA Lower sqrt price ratio
    /// @param sqrtRatioB Upper sqrt price ratio
    /// @param liquidityDelta Liquidity delta
    /// @return amount0 The amount0 delta
    function getAmount0Delta(
        uint256 sqrtRatioA,
        uint256 sqrtRatioB,
        int128 liquidityDelta
    ) internal pure returns (int256 amount0) {
        uint256 absLiquidity = liquidityDelta < 0 ? uint128(-liquidityDelta) : uint128(liquidityDelta);

        if (sqrtRatioA > sqrtRatioB) {
            (sqrtRatioA, sqrtRatioB) = (sqrtRatioB, sqrtRatioA);
        }

        uint256 numerator = absLiquidity * (sqrtRatioB - sqrtRatioA);
        uint256 denominator = sqrtRatioB;

        uint256 amount0Unsigned = mulDivRoundingUp(numerator, 1 << 96, denominator);

        amount0 = liquidityDelta < 0 ? -int256(amount0Unsigned) : int256(amount0Unsigned);
    }

    /// @notice Calculates the amount1 delta for a liquidity delta
    /// @param sqrtRatioA Lower sqrt price ratio
    /// @param sqrtRatioB Upper sqrt price ratio
    /// @param liquidityDelta Liquidity delta
    /// @return amount1 The amount1 delta
    function getAmount1Delta(
        uint256 sqrtRatioA,
        uint256 sqrtRatioB,
        int128 liquidityDelta
    ) internal pure returns (int256 amount1) {
        uint256 absLiquidity = liquidityDelta < 0 ? uint128(-liquidityDelta) : uint128(liquidityDelta);

        if (sqrtRatioA > sqrtRatioB) {
            (sqrtRatioA, sqrtRatioB) = (sqrtRatioB, sqrtRatioA);
        }

        uint256 amount1Unsigned = mulDiv(absLiquidity, sqrtRatioB - sqrtRatioA, 1 << 96);

        amount1 = liquidityDelta < 0 ? -int256(amount1Unsigned) : int256(amount1Unsigned);
    }

    /// @notice Calculates maximum liquidity for given token amounts
    /// @param sqrtRatio Current sqrt price ratio
    /// @param sqrtRatioLower Lower sqrt price ratio bound
    /// @param sqrtRatioUpper Upper sqrt price ratio bound
    /// @param amount0 Available amount of token0
    /// @param amount1 Available amount of token1
    /// @return liquidity Maximum liquidity that can be provided
    function maxLiquidity(
        uint256 sqrtRatio,
        uint256 sqrtRatioLower,
        uint256 sqrtRatioUpper,
        uint128 amount0,
        uint128 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatio <= sqrtRatioLower) {
            liquidity = maxLiquidityForToken0(sqrtRatioLower, sqrtRatioUpper, amount0);
        } else if (sqrtRatio < sqrtRatioUpper) {
            uint128 liquidity0 = maxLiquidityForToken0(sqrtRatio, sqrtRatioUpper, amount0);
            uint128 liquidity1 = maxLiquidityForToken1(sqrtRatioLower, sqrtRatio, amount1);
            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = maxLiquidityForToken1(sqrtRatioLower, sqrtRatioUpper, amount1);
        }
    }

    /// @notice Calculates maximum liquidity for a given amount of token0
    function maxLiquidityForToken0(
        uint256 sqrtRatioA,
        uint256 sqrtRatioB,
        uint128 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioA > sqrtRatioB) (sqrtRatioA, sqrtRatioB) = (sqrtRatioB, sqrtRatioA);
        uint256 intermediate = mulDiv(sqrtRatioA, sqrtRatioB, 1 << 96);
        return uint128(mulDiv(amount0, intermediate, sqrtRatioB - sqrtRatioA));
    }

    /// @notice Calculates maximum liquidity for a given amount of token1
    function maxLiquidityForToken1(
        uint256 sqrtRatioA,
        uint256 sqrtRatioB,
        uint128 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioA > sqrtRatioB) (sqrtRatioA, sqrtRatioB) = (sqrtRatioB, sqrtRatioA);
        return uint128(mulDiv(amount1, 1 << 96, sqrtRatioB - sqrtRatioA));
    }

    /// @notice Multiply and divide with full precision
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        require(denominator > prod1);

        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        uint256 twos = denominator & (~denominator + 1);
        assembly {
            denominator := div(denominator, twos)
        }

        assembly {
            prod0 := div(prod0, twos)
        }
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        uint256 inv = (3 * denominator) ^ 2;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;

        result = prod0 * inv;
        return result;
    }

    /// @notice Multiply and divide with full precision, rounding up
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}
