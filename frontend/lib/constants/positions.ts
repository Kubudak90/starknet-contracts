import { PoolPosition } from '@/lib/types/pool';
import { MAINNET_POOLS, ARBITRUM_POOLS } from './pools';

// Mock positions for demonstration
export const MOCK_POSITIONS: PoolPosition[] = [
  {
    id: 'position-1',
    poolId: 'eth-usdc-500',
    pool: MAINNET_POOLS[0], // ETH/USDC
    tokenId: 12345,
    liquidity: '5234567890123456789',
    tickLower: -887220,
    tickUpper: 887220,
    token0Amount: '2.5',
    token1Amount: '5000',
    unclaimedFees0: '0.0125',
    unclaimedFees1: '25.50',
    valueUSD: 10000,
  },
  {
    id: 'position-2',
    poolId: 'wbtc-eth-3000',
    pool: MAINNET_POOLS[3], // WBTC/ETH
    tokenId: 12346,
    liquidity: '1234567890123456789',
    tickLower: -20000,
    tickUpper: 20000,
    token0Amount: '0.15',
    token1Amount: '5.2',
    unclaimedFees0: '0.00025',
    unclaimedFees1: '0.0085',
    valueUSD: 25000,
  },
  {
    id: 'position-3',
    poolId: 'usdc-usdt-100',
    pool: MAINNET_POOLS[2], // USDC/USDT
    tokenId: 12347,
    liquidity: '8901234567890123456',
    tickLower: -100,
    tickUpper: 100,
    token0Amount: '15000',
    token1Amount: '15000',
    unclaimedFees0: '12.50',
    unclaimedFees1: '12.48',
    valueUSD: 30000,
  },
  {
    id: 'position-4',
    poolId: 'arb-eth-usdc-500',
    pool: ARBITRUM_POOLS[0], // ETH/USDC on Arbitrum
    tokenId: 12348,
    liquidity: '2345678901234567890',
    tickLower: -887220,
    tickUpper: 887220,
    token0Amount: '1.2',
    token1Amount: '2400',
    unclaimedFees0: '0.0045',
    unclaimedFees1: '9.20',
    valueUSD: 4800,
  },
];

export function getMockPositionsByChainId(chainId: number): PoolPosition[] {
  return MOCK_POSITIONS.filter((position) => position.pool.chainId === chainId);
}

export function getMockPositionById(id: string): PoolPosition | undefined {
  return MOCK_POSITIONS.find((position) => position.id === id);
}

export function isInRange(position: PoolPosition): boolean {
  // Mock implementation - in real app, compare current tick with tickLower/tickUpper
  // For demo, assume positions 1 and 3 are in range
  return position.id === 'position-1' || position.id === 'position-3' || position.id === 'position-4';
}

export function calculatePositionAPR(position: PoolPosition): number {
  // Mock APR calculation based on pool APR
  return position.pool.apr * (isInRange(position) ? 1 : 0.1);
}

export function getTotalUnclaimedFeesUSD(position: PoolPosition): number {
  // Mock price: ETH = $2000, WBTC = $40000, stablecoins = $1
  const getTokenPrice = (symbol: string): number => {
    if (symbol === 'ETH') return 2000;
    if (symbol === 'WBTC') return 40000;
    return 1; // Stablecoins
  };

  const fees0USD = parseFloat(position.unclaimedFees0) * getTokenPrice(position.pool.token0.symbol);
  const fees1USD = parseFloat(position.unclaimedFees1) * getTokenPrice(position.pool.token1.symbol);

  return fees0USD + fees1USD;
}
