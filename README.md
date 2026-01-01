# Ekubo Protocol - EVM Adaptation

Core contracts for Ekubo Protocol adapted for EVM-compatible chains.

## Overview

This is an EVM-compatible adaptation of the Ekubo Protocol, originally built for Starknet/Cairo. The protocol implements a concentrated liquidity AMM similar to Uniswap V3, with advanced features like extension hooks and efficient tick management.

## Features

- ✅ Concentrated liquidity AMM
- ✅ NFT-based position management (ERC721)
- ✅ Multi-hop routing
- ✅ Extension hooks system
- ✅ Bitmap-optimized tick search
- ✅ Gas-optimized with custom errors
- ✅ Locker pattern for reentrancy protection

## Architecture

### Core Contracts
- **EkuboCore.sol**: Main AMM engine with pool management and swap execution
- **EkuboPositions.sol**: NFT-based position manager
- **EkuboRouter.sol**: Multi-hop swap router

### Libraries
- **TickMath.sol**: Tick ↔ sqrt price conversions
- **LiquidityMath.sol**: Liquidity calculations
- **SwapMath.sol**: Swap step computation
- **SqrtPriceMath.sol**: Square root price math
- **TickBitmap.sol**: Gas-efficient tick initialization tracking

## Testing

See [test/README.md](test/README.md) for detailed testing documentation.

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash

# Install dependencies
forge install

# Run tests
forge test
```

## Gas Optimizations

- Custom errors instead of string messages (~50 gas per revert)
- Unchecked arithmetic where safe (~20-40 gas per operation)
- Bitmap-based tick search (O(1) within word vs O(n) linear scan)
- Optimized loop increments

## Development Status

Current implementation includes:
- ✅ Full swap logic with multi-tick crossing
- ✅ Position management (add/remove liquidity)
- ✅ Fee collection and accumulation
- ✅ Protocol fee management
- ✅ Extension hook system
- ✅ Bitmap tick optimization
- ✅ Comprehensive gas optimizations
- ✅ Basic test suite

## License

MIT
