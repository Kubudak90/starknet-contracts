import { Pool } from '@/lib/types/pool';
import { MAINNET_TOKENS, ARBITRUM_TOKENS, BASE_TOKENS, SEPOLIA_TOKENS } from './tokens';

// Fee tiers
export const FEE_TIERS = {
  LOWEST: 100, // 0.01%
  LOW: 500, // 0.05%
  MEDIUM: 3000, // 0.3%
  HIGH: 10000, // 1%
};

export const FEE_TIER_LABELS: Record<number, string> = {
  100: '0.01%',
  500: '0.05%',
  3000: '0.3%',
  10000: '1%',
};

// Mock pools for Mainnet
export const MAINNET_POOLS: Pool[] = [
  {
    id: 'eth-usdc-500',
    address: '0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640',
    token0: MAINNET_TOKENS[0], // ETH
    token1: MAINNET_TOKENS[1], // USDC
    fee: 500,
    tvl: 125000000,
    volume24h: 45000000,
    volume7d: 280000000,
    fees24h: 22500,
    apr: 35.5,
    tickSpacing: 10,
    liquidity: '15234567890123456789',
    chainId: 1,
  },
  {
    id: 'eth-usdt-500',
    address: '0x11b815efB8f581194ae79006d24E0d814B7697F6',
    token0: MAINNET_TOKENS[0], // ETH
    token1: MAINNET_TOKENS[2], // USDT
    fee: 500,
    tvl: 98000000,
    volume24h: 32000000,
    volume7d: 195000000,
    fees24h: 16000,
    apr: 28.2,
    tickSpacing: 10,
    liquidity: '12345678901234567890',
    chainId: 1,
  },
  {
    id: 'usdc-usdt-100',
    address: '0x3416cF6C708Da44DB2624D63ea0AAef7113527C6',
    token0: MAINNET_TOKENS[1], // USDC
    token1: MAINNET_TOKENS[2], // USDT
    fee: 100,
    tvl: 156000000,
    volume24h: 85000000,
    volume7d: 520000000,
    fees24h: 8500,
    apr: 8.5,
    tickSpacing: 1,
    liquidity: '25678901234567890123',
    chainId: 1,
  },
  {
    id: 'wbtc-eth-3000',
    address: '0xCBCdF9626bC03E24f779434178A73a0B4bad62eD',
    token0: MAINNET_TOKENS[4], // WBTC
    token1: MAINNET_TOKENS[0], // ETH
    fee: 3000,
    tvl: 75000000,
    volume24h: 18000000,
    volume7d: 112000000,
    fees24h: 54000,
    apr: 42.8,
    tickSpacing: 60,
    liquidity: '8901234567890123456',
    chainId: 1,
  },
  {
    id: 'eth-dai-3000',
    address: '0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8',
    token0: MAINNET_TOKENS[0], // ETH
    token1: MAINNET_TOKENS[3], // DAI
    fee: 3000,
    tvl: 42000000,
    volume24h: 12000000,
    volume7d: 75000000,
    fees24h: 36000,
    apr: 38.5,
    tickSpacing: 60,
    liquidity: '6789012345678901234',
    chainId: 1,
  },
];

// Mock pools for Arbitrum
export const ARBITRUM_POOLS: Pool[] = [
  {
    id: 'arb-eth-usdc-500',
    address: '0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443',
    token0: ARBITRUM_TOKENS[0], // ETH
    token1: ARBITRUM_TOKENS[1], // USDC
    fee: 500,
    tvl: 68000000,
    volume24h: 25000000,
    volume7d: 155000000,
    fees24h: 12500,
    apr: 32.5,
    tickSpacing: 10,
    liquidity: '10234567890123456789',
    chainId: 42161,
  },
  {
    id: 'arb-usdc-usdt-100',
    address: '0x8c9d3Bc4425773BD2F00C4a2aC105d8aeBb8C654',
    token0: ARBITRUM_TOKENS[1], // USDC
    token1: ARBITRUM_TOKENS[2], // USDT
    fee: 100,
    tvl: 45000000,
    volume24h: 32000000,
    volume7d: 198000000,
    fees24h: 3200,
    apr: 10.2,
    tickSpacing: 1,
    liquidity: '15678901234567890123',
    chainId: 42161,
  },
];

// Mock pools for Base
export const BASE_POOLS: Pool[] = [
  {
    id: 'base-eth-usdc-500',
    address: '0x4C36388bE6F416A29C8d8Eee81C771cE6bE14B18',
    token0: BASE_TOKENS[0], // ETH
    token1: BASE_TOKENS[1], // USDC
    fee: 500,
    tvl: 35000000,
    volume24h: 12000000,
    volume7d: 75000000,
    fees24h: 6000,
    apr: 28.5,
    tickSpacing: 10,
    liquidity: '8234567890123456789',
    chainId: 8453,
  },
];

// Mock pools for Sepolia
export const SEPOLIA_POOLS: Pool[] = [
  {
    id: 'sepolia-eth-usdc-3000',
    address: '0x1234567890123456789012345678901234567890',
    token0: SEPOLIA_TOKENS[0], // ETH
    token1: SEPOLIA_TOKENS[1], // USDC
    fee: 3000,
    tvl: 100000,
    volume24h: 25000,
    volume7d: 150000,
    fees24h: 75,
    apr: 15.5,
    tickSpacing: 60,
    liquidity: '1234567890123456789',
    chainId: 11155111,
  },
];

export const POOLS_BY_CHAIN: Record<number, Pool[]> = {
  1: MAINNET_POOLS,
  42161: ARBITRUM_POOLS,
  8453: BASE_POOLS,
  11155111: SEPOLIA_POOLS,
};

export function getPoolsByChainId(chainId: number): Pool[] {
  return POOLS_BY_CHAIN[chainId] || [];
}

export function findPool(chainId: number, poolId: string): Pool | undefined {
  const pools = getPoolsByChainId(chainId);
  return pools.find((pool) => pool.id === poolId || pool.address.toLowerCase() === poolId.toLowerCase());
}

export function getPoolDisplayName(pool: Pool): string {
  return `${pool.token0.symbol}/${pool.token1.symbol}`;
}

export function formatPoolFee(fee: number): string {
  return FEE_TIER_LABELS[fee] || `${fee / 10000}%`;
}
