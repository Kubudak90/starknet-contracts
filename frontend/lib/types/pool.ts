import { Token } from './token';

export interface Pool {
  id: string;
  address: string;
  token0: Token;
  token1: Token;
  fee: number; // Fee tier (e.g., 500 = 0.05%, 3000 = 0.3%, 10000 = 1%)
  tvl: number; // Total Value Locked in USD
  volume24h: number; // 24h trading volume in USD
  volume7d: number; // 7d trading volume in USD
  fees24h: number; // 24h fees in USD
  apr: number; // Annual Percentage Rate
  tickSpacing: number;
  liquidity: string; // Current liquidity
  sqrtPriceX96?: string;
  tick?: number;
  chainId: number;
}

export interface PoolPosition {
  id: string;
  poolId: string;
  pool: Pool;
  tokenId: number; // NFT token ID
  liquidity: string;
  tickLower: number;
  tickUpper: number;
  token0Amount: string;
  token1Amount: string;
  unclaimedFees0: string;
  unclaimedFees1: string;
  valueUSD: number;
}

export interface LiquidityRange {
  min: number;
  max: number;
  current: number;
}

export interface AddLiquidityParams {
  pool: Pool;
  amount0: string;
  amount1: string;
  tickLower: number;
  tickUpper: number;
  slippage: number;
}

export interface RemoveLiquidityParams {
  positionId: string;
  liquidity: string;
  percentage: number;
  slippage: number;
}
