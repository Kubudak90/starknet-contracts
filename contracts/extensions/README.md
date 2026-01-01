# Ekubo Protocol Extensions

Extensions enhance the core protocol with additional functionality while maintaining modularity and composability.

## TWAMM Extension

### Overview

The Time-Weighted Average Market Maker (TWAMM) extension enables users to execute large trades gradually over time, significantly reducing price impact and MEV exposure.

### How It Works

1. **Order Submission**: Users submit long-term orders specifying:
   - Total amount to sell
   - Duration over which to execute
   - Direction (token0 → token1 or token1 → token0)

2. **Virtual Order Execution**:
   - Orders are executed virtually on every swap
   - Sell rate = total amount / duration (amount per second)
   - Execution is pro-rated based on elapsed time

3. **Order Cancellation**:
   - Owners can cancel orders at any time
   - Remaining unexecuted amount is returned

### Features

- ✅ Time-weighted execution reduces price impact
- ✅ Automatic execution on every swap via beforeSwap hook
- ✅ Order cancellation support
- ✅ Expired order cleanup
- ✅ Gas-optimized with unchecked arithmetic
- ✅ Per-pool order tracking

### Usage Example

```solidity
// Deploy TWAMM extension
TWAMMExtension twamm = new TWAMMExtension(address(core), owner);

// Create pool with TWAMM extension
DataTypes.PoolKey memory poolKey = DataTypes.PoolKey({
    token0: address(tokenA),
    token1: address(tokenB),
    fee: 3000,
    tickSpacing: 60,
    extension: address(twamm)  // Link TWAMM to pool
});

// Initialize pool
core.initializePool(poolKey, 0);

// Submit 10,000 token order to execute over 1 hour
bytes32 orderId = twamm.submitOrder(
    poolKey,
    10000 ether,      // sellAmount
    3600,             // duration (1 hour)
    false             // selling token0
);

// Cancel order if needed
twamm.cancelOrder(orderId);

// Check order status
TWAMMExtension.Order memory order = twamm.getOrder(orderId);
```

### Extension Hooks Used

- **afterInitializePool**: Set up initial timestamp for pool
- **beforeSwap**: Execute pending virtual orders before each swap

### Gas Considerations

- Order submission: ~100k gas (includes storage writes)
- Virtual execution: Variable (depends on number of active orders)
- Order cleanup: Amortized across swaps

### Architecture

```
User → submitOrder() → TWAMMExtension
                          ↓
                    Track sell rates
                          ↓
Any Swap → beforeSwap hook → _executeVirtualOrders()
                                      ↓
                              Execute time-weighted amounts
                                      ↓
                              Update pool state
                                      ↓
                              Clean up expired orders
```

### Storage Layout

```solidity
// Per-pool state
struct PoolOrders {
    uint256 lastExecutionTime;    // Last time orders were executed
    uint256 sellRate0For1;         // Token0 → Token1 rate (per second)
    uint256 sellRate1For0;         // Token1 → Token0 rate (per second)
}

// Per-order state
struct Order {
    address owner;                 // Order owner
    uint256 sellAmount;            // Total amount to sell
    uint256 sellRate;              // Amount per second
    uint256 expirationTime;        // When order expires
    bool isToken1;                 // Direction
    uint256 filledAmount;          // Amount executed so far
    bool cancelled;                // Cancellation flag
}
```

### Security Considerations

1. **Reentrancy**: Uses core's reentrancy protection
2. **Access Control**: Only order owners can cancel their orders
3. **Time Manipulation**: Uses block.timestamp (acceptable for TWAMM use case)
4. **Integer Overflow**: Protected with Solidity 0.8+ and unchecked where safe

### Future Enhancements

- [ ] Partial order cancellation
- [ ] Order modification (change duration/amount)
- [ ] Limit order integration
- [ ] Price bounds for orders
- [ ] Batch order submission
- [ ] Order NFT representation
- [ ] Advanced order types (DCA, grid trading)

### Testing

See test suite for TWAMM extension tests (planned).

### References

- [TWAMM Paper (Paradigm)](https://www.paradigm.xyz/2021/07/twamm)
- Original concept by Dave White, Dan Robinson, and Uniswap Labs

## Creating Custom Extensions

Extensions must implement the `IExtension` interface and register their call points:

```solidity
contract CustomExtension is IExtension {
    ICore public immutable core;

    constructor(address _core) {
        core = ICore(_core);

        // Register which hooks you want to use
        DataTypes.CallPoints memory callPoints = DataTypes.CallPoints({
            beforeInitializePool: false,
            afterInitializePool: false,
            beforeUpdatePosition: true,  // Your hook
            afterUpdatePosition: false,
            beforeSwap: false,
            afterSwap: true,             // Your hook
            beforeCollectFees: false,
            afterCollectFees: false
        });

        core.setCallPoints(callPoints);
    }

    // Implement only the hooks you registered
    function beforeUpdatePosition(...) external override {
        require(msg.sender == address(core), "Only core");
        // Your logic
    }

    function afterSwap(...) external override {
        require(msg.sender == address(core), "Only core");
        // Your logic
    }

    // Stub out unused hooks
    function beforeInitializePool(...) external pure override {
        revert("Not implemented");
    }
    // ... etc
}
```

### Extension Ideas

- **Limit Orders**: Execute swaps when price reaches target
- **Range Orders**: Like limit orders but with concentrated liquidity
- **Stop Loss**: Automatic position closure on adverse price movement
- **Oracle TWAP**: Time-weighted average price tracking
- **Volatility Index**: Track and expose pool volatility
- **Dynamic Fees**: Adjust fees based on market conditions
- **MEV Protection**: Additional MEV mitigation strategies
