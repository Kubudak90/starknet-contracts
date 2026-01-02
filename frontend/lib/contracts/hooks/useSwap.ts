import { useWriteContract, useSimulateContract, useWaitForTransactionReceipt } from 'wagmi';
import { useChainId } from 'wagmi';
import { EkuboRouterABI } from '../abis/EkuboRouter';
import { getContractAddresses } from '../addresses';

export interface SwapParams {
  tokenIn: `0x${string}`;
  tokenOut: `0x${string}`;
  amountIn: bigint;
  minAmountOut: bigint;
  recipient: `0x${string}`;
}

export function useSwap() {
  const chainId = useChainId();
  const addresses = getContractAddresses(chainId);

  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const swap = async (params: SwapParams) => {
    // Construct route node (simplified - single hop)
    const route = {
      poolKey: '0x0000000000000000000000000000000000000000000000000000000000000000' as `0x${string}`,
      sqrtRatioLimit: BigInt(0), // 0 means no limit
      skipAhead: BigInt(0),
    };

    const tokenAmount = {
      token: params.tokenIn,
      amount: params.amountIn as any, // int128
    };

    return writeContract({
      address: addresses.router,
      abi: EkuboRouterABI,
      functionName: 'swap',
      args: [route, tokenAmount],
    });
  };

  return {
    swap,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error,
  };
}

export function useQuoteSwap(tokenIn?: `0x${string}`, tokenOut?: `0x${string}`, amountIn?: bigint) {
  const chainId = useChainId();
  const addresses = getContractAddresses(chainId);

  const route = {
    poolKey: '0x0000000000000000000000000000000000000000000000000000000000000000' as `0x${string}`,
    sqrtRatioLimit: BigInt(0),
    skipAhead: BigInt(0),
  };

  const tokenAmount = tokenIn && amountIn ? {
    token: tokenIn,
    amount: amountIn as any,
  } : undefined;

  // For now, return mock data since we don't have deployed contracts
  // In production, this would use useReadContract
  return {
    data: tokenAmount ? {
      amount0: amountIn || BigInt(0),
      amount1: amountIn ? (amountIn * BigInt(2000)) / BigInt(10 ** 18) : BigInt(0), // Mock: 1 ETH = 2000 USDC
    } : undefined,
    isLoading: false,
    error: null,
  };
}
