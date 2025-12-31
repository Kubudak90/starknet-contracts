// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SqrtPriceMath} from "./SqrtPriceMath.sol";

/// @title SwapMath
/// @notice Computes the result of swapping tokens
library SwapMath {
    /// @notice Result of a swap step
    struct SwapResult {
        int256 consumedAmount;      // How much was consumed (including fees)
        uint128 calculatedAmount;   // How much of the other token is given
        uint256 sqrtRatioNext;      // Next sqrt price ratio
        uint128 feeAmount;          // Fee collected
    }

    /// @notice Check if price is increasing based on swap direction
    /// @param exactOutput True if exact output swap
    /// @param isToken1 True if swapping token0 for token1
    /// @return True if price is increasing
    function isPriceIncreasing(bool exactOutput, bool isToken1) internal pure returns (bool) {
        // sqrt_ratio is expressed in token1/token0, thus:
        // negative token0 = true ^ false = true = increasing
        // negative token1 = true ^ true = false = decreasing
        // positive token0 = false ^ false = false = decreasing
        // positive token1 = false ^ true = true = increasing
        return exactOutput != isToken1;
    }

    /// @notice Compute the result of a swap
    /// @param sqrtRatio Current sqrt price ratio
    /// @param liquidity Available liquidity
    /// @param sqrtRatioLimit Price limit
    /// @param amount Amount to swap (positive = exact input, negative = exact output)
    /// @param isToken1 Direction of swap
    /// @param fee Fee rate (0.128 fixed point)
    /// @return result Swap result
    function computeSwapStep(
        uint256 sqrtRatio,
        uint128 liquidity,
        uint256 sqrtRatioLimit,
        int256 amount,
        bool isToken1,
        uint128 fee
    ) internal pure returns (SwapResult memory result) {
        // No amount traded or limit reached means no-op
        if (amount == 0 || sqrtRatio == sqrtRatioLimit) {
            return SwapResult({
                consumedAmount: 0,
                calculatedAmount: 0,
                sqrtRatioNext: sqrtRatio,
                feeAmount: 0
            });
        }

        bool increasing = isPriceIncreasing(amount < 0, isToken1);

        // Ensure limit is in correct direction
        require((sqrtRatioLimit > sqrtRatio) == increasing, "DIRECTION");

        // If liquidity is 0, move to limit price
        if (liquidity == 0) {
            return SwapResult({
                consumedAmount: 0,
                calculatedAmount: 0,
                sqrtRatioNext: sqrtRatioLimit,
                feeAmount: 0
            });
        }

        // Calculate price impact amount (after fee deduction for exact input)
        int256 priceImpactAmount;
        if (amount < 0) {
            // Exact output - full amount impacts price
            priceImpactAmount = amount;
        } else {
            // Exact input - deduct fee first
            uint128 feeAmount = computeFee(uint128(uint256(amount)), fee);
            priceImpactAmount = int256(uint256(uint128(uint256(amount)) - feeAmount));
        }

        // Compute next sqrt ratio from the price impact amount
        (bool success, uint256 sqrtRatioNextFromAmount) = isToken1
            ? SqrtPriceMath.getNextSqrtPriceFromAmount1(sqrtRatio, liquidity, priceImpactAmount)
            : SqrtPriceMath.getNextSqrtPriceFromAmount0(sqrtRatio, liquidity, priceImpactAmount);

        bool limited = !success || (sqrtRatioNextFromAmount > sqrtRatioLimit) == increasing;

        if (limited) {
            // Hit the limit - calculate amounts at limit price
            uint256 sqrtRatioNext = sqrtRatioLimit;

            (int256 specifiedAmountDelta, uint128 calculatedAmountDelta) = isToken1
                ? (
                    int256(uint256(SqrtPriceMath.getAmount1Delta(sqrtRatioLimit, sqrtRatio, liquidity, amount >= 0))),
                    SqrtPriceMath.getAmount0Delta(sqrtRatioLimit, sqrtRatio, liquidity, amount < 0)
                )
                : (
                    int256(uint256(SqrtPriceMath.getAmount0Delta(sqrtRatioLimit, sqrtRatio, liquidity, amount >= 0))),
                    SqrtPriceMath.getAmount1Delta(sqrtRatioLimit, sqrtRatio, liquidity, amount < 0)
                );

            if (amount < 0) {
                specifiedAmountDelta = -specifiedAmountDelta;
            }

            int256 consumedAmount;
            uint128 feeAmount;

            if (amount < 0) {
                // Exact output
                uint128 beforeFee = amountBeforeFee(calculatedAmountDelta, fee);
                consumedAmount = int256(uint256(beforeFee));
                calculatedAmount = calculatedAmountDelta;
                feeAmount = beforeFee - calculatedAmountDelta;
            } else {
                // Exact input
                uint128 beforeFee = amountBeforeFee(uint128(uint256(specifiedAmountDelta)), fee);
                consumedAmount = int256(uint256(beforeFee));
                calculatedAmount = calculatedAmountDelta;
                feeAmount = beforeFee - uint128(uint256(specifiedAmountDelta));
            }

            return SwapResult({
                consumedAmount: consumedAmount,
                calculatedAmount: calculatedAmount,
                sqrtRatioNext: sqrtRatioNext,
                feeAmount: feeAmount
            });
        }

        uint256 sqrtRatioNext = sqrtRatioNextFromAmount;

        // Amount was not enough to move price
        if (sqrtRatioNext == sqrtRatio) {
            require(amount >= 0, "INPUT_SMALL_AMOUNT");
            return SwapResult({
                consumedAmount: amount,
                calculatedAmount: 0,
                sqrtRatioNext: sqrtRatio,
                feeAmount: uint128(uint256(amount))
            });
        }

        // Calculate the other token amount
        uint128 calculatedAmountExcludingFee = isToken1
            ? SqrtPriceMath.getAmount0Delta(sqrtRatioNext, sqrtRatio, liquidity, amount < 0)
            : SqrtPriceMath.getAmount1Delta(sqrtRatioNext, sqrtRatio, liquidity, amount < 0);

        uint128 calculatedAmount;
        uint128 feeAmount;

        if (amount < 0) {
            // Exact output - add fee to calculated amount
            uint128 includingFee = amountBeforeFee(calculatedAmountExcludingFee, fee);
            calculatedAmount = includingFee;
            feeAmount = includingFee - calculatedAmountExcludingFee;
        } else {
            // Exact input
            calculatedAmount = calculatedAmountExcludingFee;
            feeAmount = uint128(uint256(amount)) - uint128(uint256(priceImpactAmount));
        }

        return SwapResult({
            consumedAmount: amount,
            calculatedAmount: calculatedAmount,
            sqrtRatioNext: sqrtRatioNext,
            feeAmount: feeAmount
        });
    }

    /// @notice Compute fee amount
    /// @param amount Amount to compute fee for
    /// @param fee Fee rate (0.128 fixed point)
    /// @return feeAmount Fee amount (rounded up)
    function computeFee(uint128 amount, uint128 fee) internal pure returns (uint128 feeAmount) {
        uint256 product = uint256(amount) * uint256(fee);
        feeAmount = uint128((product >> 128) + (product & ((1 << 128) - 1) == 0 ? 0 : 1));
    }

    /// @notice Get amount before fee was applied
    /// @param afterFee Amount after fee
    /// @param fee Fee rate (0.128 fixed point)
    /// @return beforeFee Amount before fee (rounded up)
    function amountBeforeFee(uint128 afterFee, uint128 fee) internal pure returns (uint128 beforeFee) {
        uint256 denominator = (uint256(1) << 128) - uint256(fee);
        uint256 numerator = uint256(afterFee) << 128;

        beforeFee = uint128((numerator / denominator) + ((numerator % denominator) == 0 ? 0 : 1));
    }
}
