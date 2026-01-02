# Ekubo Protocol Smart Contract Integration

This directory contains the smart contract ABIs, addresses, and React hooks for interacting with Ekubo Protocol on EVM-compatible chains.

## 📁 Directory Structure

```
lib/contracts/
├── abis/                    # Contract ABIs
│   ├── EkuboCore.ts        # Core protocol (pools, swaps, positions)
│   ├── EkuboPositions.ts   # NFT position manager
│   └── EkuboRouter.ts      # Swap router
├── hooks/                   # React hooks for contract interaction
│   ├── useSwap.ts          # Swap operations
│   ├── usePosition.ts      # Position management (add/remove liquidity, collect fees)
│   └── usePool.ts          # Pool data queries
├── addresses.ts             # Contract addresses by chain
└── index.ts                 # Main exports
```

## 🚀 Quick Start

### 1. Deploy Contracts

First, deploy the Ekubo Protocol contracts to your target EVM chain(s):

```bash
# Example deployment (adjust based on your deployment setup)
forge create --rpc-url <RPC_URL> \
  --private-key <PRIVATE_KEY> \
  src/EkuboCore.sol:EkuboCore

forge create --rpc-url <RPC_URL> \
  --private-key <PRIVATE_KEY> \
  src/EkuboPositions.sol:EkuboPositions

forge create --rpc-url <RPC_URL> \
  --private-key <PRIVATE_KEY> \
  src/EkuboRouter.sol:EkuboRouter
```

### 2. Update Contract Addresses

After deployment, update the contract addresses in `addresses.ts`:

```typescript
// lib/contracts/addresses.ts

export const MAINNET_ADDRESSES: ContractAddresses = {
  core: '0xYourCoreContractAddress',
  positions: '0xYourPositionsContractAddress',
  router: '0xYourRouterContractAddress',
};

// Repeat for other chains (Sepolia, Arbitrum, Base)
```

### 3. Use in Components

Import and use the hooks in your React components:

```typescript
import { useSwap, useAddLiquidity, useCollectFees } from '@/lib/contracts/hooks';

function MyComponent() {
  const { swap, isPending, isSuccess } = useSwap();

  const handleSwap = async () => {
    await swap({
      tokenIn: '0x...',
      tokenOut: '0x...',
      amountIn: BigInt('1000000000000000000'), // 1 token
      minAmountOut: BigInt('900000000000000000'), // 0.9 token (10% slippage)
      recipient: '0xYourAddress',
    });
  };

  return (
    <button onClick={handleSwap} disabled={isPending}>
      {isPending ? 'Swapping...' : 'Swap'}
    </button>
  );
}
```

## 📚 Available Hooks

### Swap Hooks

#### `useSwap()`
Execute token swaps on the DEX.

```typescript
const { swap, hash, isPending, isConfirming, isSuccess, error } = useSwap();

await swap({
  tokenIn: '0x...', // Input token address
  tokenOut: '0x...', // Output token address
  amountIn: BigInt('1000000000000000000'),
  minAmountOut: BigInt('900000000000000000'),
  recipient: '0x...',
});
```

#### `useQuoteSwap(tokenIn, tokenOut, amountIn)`
Get price quote for a swap (read-only).

```typescript
const { data, isLoading, error } = useQuoteSwap(
  '0xTokenInAddress',
  '0xTokenOutAddress',
  BigInt('1000000000000000000')
);

// data contains { amount0, amount1 }
```

### Position Hooks

#### `useAddLiquidity()`
Add liquidity to a pool and mint a position NFT.

```typescript
const { addLiquidity, hash, isPending, isConfirming, isSuccess, error } = useAddLiquidity();

await addLiquidity({
  pool: poolObject, // Pool from getPoolsByChainId()
  amount0: BigInt('1000000000000000000'),
  amount1: BigInt('2000000000'),
  tickLower: -887220,
  tickUpper: 887220,
  minLiquidity: BigInt('0'),
});
```

#### `useRemoveLiquidity()`
Remove liquidity from a position.

```typescript
const { removeLiquidity, hash, isPending, isConfirming, isSuccess, error } = useRemoveLiquidity();

await removeLiquidity({
  tokenId: BigInt('12345'),
  pool: poolObject,
  liquidity: BigInt('1000000000000000000'),
  minAmount0: BigInt('0'),
  minAmount1: BigInt('0'),
  tickLower: -887220,
  tickUpper: 887220,
});
```

#### `useCollectFees()`
Collect accumulated fees from a position.

```typescript
const { collectFees, hash, isPending, isConfirming, isSuccess, error } = useCollectFees();

await collectFees(
  BigInt('12345'), // tokenId
  poolObject,
  -887220, // tickLower
  887220   // tickUpper
);
```

#### `usePositionInfo(tokenId, pool, tickLower, tickUpper)`
Get information about a position (read-only).

```typescript
const { data, isLoading, error } = usePositionInfo(
  BigInt('12345'),
  poolObject,
  -887220,
  887220
);

// data contains { sqrtPriceX96, liquidity, amount0, amount1, fees0, fees1 }
```

### Pool Hooks

#### `usePoolPrice(pool)`
Get the current price of a pool (read-only).

```typescript
const { data, isLoading, error } = usePoolPrice(poolObject);

// data contains { sqrtPriceX96, tick }
```

#### `usePoolLiquidity(pool)`
Get the current liquidity of a pool (read-only).

```typescript
const { data, isLoading, error } = usePoolLiquidity(poolObject);

// data is bigint representing liquidity
```

## 🔧 Contract ABIs

### EkuboCore
Core protocol functions:
- `getPoolPrice(poolKey)` - Get pool price
- `getPoolLiquidity(poolKey)` - Get pool liquidity
- `getPosition(poolKey, positionKey)` - Get position state
- `initializePool(poolKey, initialTick)` - Initialize a new pool

### EkuboPositions
Position management functions:
- `mintAndDeposit(poolKey, bounds, minLiquidity)` - Mint NFT and add liquidity
- `deposit(tokenId, poolKey, bounds, minLiquidity)` - Add liquidity to existing position
- `withdraw(tokenId, poolKey, bounds, liquidity, minToken0, minToken1)` - Remove liquidity
- `collectFees(tokenId, poolKey, bounds)` - Collect fees
- `getTokenInfo(tokenId, poolKey, bounds)` - Get position info

### EkuboRouter
Swap routing functions:
- `swap(route, tokenAmount)` - Single-hop swap
- `multihopSwap(route[], tokenAmount)` - Multi-hop swap
- `quoteSwap(route, tokenAmount)` - Get swap quote
- `quoteMultihopSwap(route[], tokenAmount)` - Get multi-hop quote

## 🌐 Supported Networks

The contracts are configured for:
- **Ethereum Mainnet** (chainId: 1)
- **Sepolia Testnet** (chainId: 11155111)
- **Arbitrum One** (chainId: 42161)
- **Base** (chainId: 8453)

## 🔐 Security Notes

1. **Slippage Protection**: Always set appropriate `minAmountOut` values when swapping
2. **Gas Limits**: Some operations may require higher gas limits for complex multi-hop swaps
3. **Approvals**: Remember to approve token spending before executing swaps or adding liquidity
4. **Price Impact**: Check price impact before executing large trades

## 🛠️ Development

### Testing Hooks Locally

```typescript
// Mock mode is enabled by default when contracts aren't deployed
// The hooks will return simulated data for development

const { data } = useQuoteSwap(tokenIn, tokenOut, amountIn);
// Returns mock quote data even without deployed contracts
```

### Adding New Functions

1. Add function to appropriate ABI file in `abis/`
2. Create or update hook in `hooks/`
3. Export from `hooks/index.ts`
4. Use in components

### Type Safety

All ABIs are typed using TypeScript's `as const` assertion, ensuring full type safety when using `wagmi` hooks.

## 📖 Further Reading

- [Wagmi Documentation](https://wagmi.sh/)
- [Viem Documentation](https://viem.sh/)
- [RainbowKit Documentation](https://www.rainbowkit.com/)
- [Concentrated Liquidity Math](https://uniswap.org/whitepaper-v3.pdf)

## ⚠️ Important Notes

- Contract addresses are currently set to placeholder values (`0x00...01`, `0x00...02`, etc.)
- Update these addresses after deploying contracts to your target networks
- The frontend currently uses mock data for development - real contract calls will work once addresses are updated
- Always test on testnets before deploying to mainnet
