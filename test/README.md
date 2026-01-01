# Ekubo Core Test Suite

Comprehensive Foundry-based test suite for the Ekubo Protocol EVM adaptation.

## Setup

### 1. Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Install Dependencies

```bash
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install foundry-rs/forge-std --no-commit
```

### 3. Build Contracts

```bash
forge build
```

## Running Tests

### Run all tests
```bash
forge test
```

### Run with verbosity
```bash
forge test -vvv
```

### Run specific test
```bash
forge test --match-test testInitializePool
```

### Run with gas reporting
```bash
forge test --gas-report
```

### Run with coverage
```bash
forge coverage
```

## Test Structure

```
test/
├── EkuboCore.t.sol      # Main core contract tests
├── mocks/
│   ├── MockERC20.sol    # ERC20 token mock
│   └── MockLocker.sol   # Locker pattern implementation
└── README.md            # This file
```

## Test Coverage

### EkuboCore.t.sol
- ✅ Pool key hashing
- ✅ Pool initialization
- ✅ Double initialization prevention
- ✅ Token ordering validation
- ✅ Zero address validation
- ✅ Maybe initialize pool (idempotent)
- ✅ Add liquidity to positions
- ✅ Invalid bounds validation
- ✅ Swap requires initialization
- ✅ Locker state management
- ✅ Protocol fee tracking
- ✅ Owner-only functions

## Mocks

### MockERC20
Simple ERC20 implementation with mint/burn for testing.

### MockLocker
Implements the ILocker interface to test the locker pattern with:
- Pool initialization
- Position updates with automatic delta settlement
- Swaps with automatic delta settlement

## Writing New Tests

Example test:

```solidity
function testYourFeature() public {
    // Initialize pool
    locker.executeInitializePool(poolKey, INITIAL_TICK);

    // Your test logic here

    // Assertions
    assertEq(actualValue, expectedValue);
}
```

## Gas Optimization

The test suite includes gas snapshots. Run:

```bash
forge snapshot
```

This creates `.gas-snapshot` file for tracking gas usage over time.

## Continuous Integration

Tests are designed to run in CI environments. Example GitHub Actions:

```yaml
- name: Run tests
  run: forge test --gas-report
```
