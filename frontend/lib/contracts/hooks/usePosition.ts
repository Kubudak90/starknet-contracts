import { useWriteContract, useReadContract, useWaitForTransactionReceipt } from 'wagmi';
import { useChainId } from 'wagmi';
import { EkuboPositionsABI } from '../abis/EkuboPositions';
import { getContractAddresses } from '../addresses';
import { Pool } from '@/lib/types/pool';

export interface AddLiquidityParams {
  pool: Pool;
  amount0: bigint;
  amount1: bigint;
  tickLower: number;
  tickUpper: number;
  minLiquidity: bigint;
}

export interface RemoveLiquidityParams {
  tokenId: bigint;
  pool: Pool;
  liquidity: bigint;
  minAmount0: bigint;
  minAmount1: bigint;
  tickLower: number;
  tickUpper: number;
}

export function useAddLiquidity() {
  const chainId = useChainId();
  const addresses = getContractAddresses(chainId);

  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const addLiquidity = async (params: AddLiquidityParams) => {
    const poolKey = {
      token0: params.pool.token0.address as `0x${string}`,
      token1: params.pool.token1.address as `0x${string}`,
      fee: params.pool.fee,
      tickSpacing: params.pool.tickSpacing,
      extension: '0x0000000000000000000000000000000000000000' as `0x${string}`,
    };

    const bounds = {
      lower: BigInt(params.tickLower),
      upper: BigInt(params.tickUpper),
    };

    return writeContract({
      address: addresses.positions,
      abi: EkuboPositionsABI,
      functionName: 'mintAndDeposit',
      args: [poolKey, bounds, params.minLiquidity],
    });
  };

  return {
    addLiquidity,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error,
  };
}

export function useRemoveLiquidity() {
  const chainId = useChainId();
  const addresses = getContractAddresses(chainId);

  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const removeLiquidity = async (params: RemoveLiquidityParams) => {
    const poolKey = {
      token0: params.pool.token0.address as `0x${string}`,
      token1: params.pool.token1.address as `0x${string}`,
      fee: params.pool.fee,
      tickSpacing: params.pool.tickSpacing,
      extension: '0x0000000000000000000000000000000000000000' as `0x${string}`,
    };

    const bounds = {
      lower: BigInt(params.tickLower),
      upper: BigInt(params.tickUpper),
    };

    return writeContract({
      address: addresses.positions,
      abi: EkuboPositionsABI,
      functionName: 'withdraw',
      args: [params.tokenId, poolKey, bounds, params.liquidity, params.minAmount0, params.minAmount1],
    });
  };

  return {
    removeLiquidity,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error,
  };
}

export function useCollectFees() {
  const chainId = useChainId();
  const addresses = getContractAddresses(chainId);

  const { writeContract, data: hash, isPending, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const collectFees = async (tokenId: bigint, pool: Pool, tickLower: number, tickUpper: number) => {
    const poolKey = {
      token0: pool.token0.address as `0x${string}`,
      token1: pool.token1.address as `0x${string}`,
      fee: pool.fee,
      tickSpacing: pool.tickSpacing,
      extension: '0x0000000000000000000000000000000000000000' as `0x${string}`,
    };

    const bounds = {
      lower: BigInt(tickLower),
      upper: BigInt(tickUpper),
    };

    return writeContract({
      address: addresses.positions,
      abi: EkuboPositionsABI,
      functionName: 'collectFees',
      args: [tokenId, poolKey, bounds],
    });
  };

  return {
    collectFees,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    error,
  };
}

export function usePositionInfo(tokenId?: bigint, pool?: Pool, tickLower?: number, tickUpper?: number) {
  const chainId = useChainId();
  const addresses = getContractAddresses(chainId);

  // For now, return mock data since we don't have deployed contracts
  // In production, this would use useReadContract
  return {
    data: tokenId && pool ? {
      sqrtPriceX96: BigInt(0),
      liquidity: BigInt(0),
      amount0: BigInt(0),
      amount1: BigInt(0),
      fees0: BigInt(0),
      fees1: BigInt(0),
    } : undefined,
    isLoading: false,
    error: null,
  };
}
