// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {EkuboCore} from "../contracts/core/EkuboCore.sol";
import {DataTypes} from "../contracts/types/DataTypes.sol";
import {TickMath} from "../contracts/libraries/TickMath.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockLocker} from "./mocks/MockLocker.sol";

contract EkuboCoreTest is Test {
    EkuboCore public core;
    MockERC20 public token0;
    MockERC20 public token1;
    MockLocker public locker;

    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);

    DataTypes.PoolKey public poolKey;

    uint128 constant FEE = 3000; // 0.3% in basis points scaled to Q128
    uint128 constant TICK_SPACING = 60;
    int128 constant INITIAL_TICK = 0;

    function setUp() public {
        // Deploy core contract
        core = new EkuboCore(owner);

        // Deploy mock tokens (ensure proper ordering)
        MockERC20 tokenA = new MockERC20("Token A", "TKA", 18);
        MockERC20 tokenB = new MockERC20("Token B", "TKB", 18);

        // Ensure token0 < token1
        if (address(tokenA) < address(tokenB)) {
            token0 = tokenA;
            token1 = tokenB;
        } else {
            token0 = tokenB;
            token1 = tokenA;
        }

        // Deploy locker
        locker = new MockLocker(address(core));

        // Setup pool key
        poolKey = DataTypes.PoolKey({
            token0: address(token0),
            token1: address(token1),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            extension: address(0)
        });

        // Mint tokens to users
        token0.mint(user1, 1000000 ether);
        token1.mint(user1, 1000000 ether);
        token0.mint(user2, 1000000 ether);
        token1.mint(user2, 1000000 ether);
        token0.mint(address(locker), 1000000 ether);
        token1.mint(address(locker), 1000000 ether);
    }

    function testPoolKeyHash() public {
        bytes32 hash = core.getPoolKeyHash(poolKey);
        assertEq(hash, keccak256(abi.encode(poolKey)));
    }

    function testInitializePool() public {
        locker.executeInitializePool(poolKey, INITIAL_TICK);

        DataTypes.PoolPrice memory price = core.getPoolPrice(poolKey);
        assertEq(price.tick, INITIAL_TICK);
        assertEq(price.sqrtRatio, TickMath.tickToSqrtRatio(INITIAL_TICK));
    }

    function testCannotInitializePoolTwice() public {
        locker.executeInitializePool(poolKey, INITIAL_TICK);

        vm.expectRevert(EkuboCore.PoolAlreadyInitialized.selector);
        locker.executeInitializePool(poolKey, INITIAL_TICK);
    }

    function testCannotInitializeWithInvalidTokenOrder() public {
        DataTypes.PoolKey memory invalidPoolKey = DataTypes.PoolKey({
            token0: address(token1), // Wrong order
            token1: address(token0),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            extension: address(0)
        });

        vm.expectRevert(EkuboCore.InvalidTokenOrder.selector);
        locker.executeInitializePool(invalidPoolKey, INITIAL_TICK);
    }

    function testCannotInitializeWithZeroAddress() public {
        DataTypes.PoolKey memory invalidPoolKey = DataTypes.PoolKey({
            token0: address(0),
            token1: address(token1),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            extension: address(0)
        });

        vm.expectRevert(EkuboCore.TokenCannotBeZero.selector);
        locker.executeInitializePool(invalidPoolKey, INITIAL_TICK);
    }

    function testMaybeInitializePool() public {
        (bool initialized, uint256 sqrtRatio) = core.maybeInitializePool(poolKey, INITIAL_TICK);

        assertTrue(initialized);
        assertEq(sqrtRatio, TickMath.tickToSqrtRatio(INITIAL_TICK));

        // Try again - should not initialize
        (initialized, sqrtRatio) = core.maybeInitializePool(poolKey, INITIAL_TICK);
        assertFalse(initialized);
        assertEq(sqrtRatio, TickMath.tickToSqrtRatio(INITIAL_TICK));
    }

    function testUpdatePositionAddsLiquidity() public {
        // Initialize pool first
        locker.executeInitializePool(poolKey, INITIAL_TICK);

        DataTypes.UpdatePositionParameters memory params = DataTypes.UpdatePositionParameters({
            salt: bytes32(0),
            bounds: DataTypes.Bounds({lower: -120, upper: 120}),
            liquidityDelta: 1000000
        });

        locker.executeUpdatePosition(poolKey, params);

        // Check position was created
        DataTypes.PositionKey memory posKey = DataTypes.PositionKey({
            owner: address(locker),
            salt: bytes32(0),
            bounds: params.bounds
        });

        DataTypes.Position memory position = core.getPosition(poolKey, posKey);
        assertEq(position.liquidity, 1000000);
    }

    function testUpdatePositionInvalidBounds() public {
        locker.executeInitializePool(poolKey, INITIAL_TICK);

        DataTypes.UpdatePositionParameters memory params = DataTypes.UpdatePositionParameters({
            salt: bytes32(0),
            bounds: DataTypes.Bounds({lower: 120, upper: -120}), // Invalid: lower > upper
            liquidityDelta: 1000000
        });

        vm.expectRevert(EkuboCore.InvalidBoundsOrder.selector);
        locker.executeUpdatePosition(poolKey, params);
    }

    function testSwapRequiresPoolInitialization() public {
        DataTypes.SwapParameters memory params = DataTypes.SwapParameters({
            amount: 1000,
            isToken1: false,
            sqrtRatioLimit: TickMath.MIN_SQRT_RATIO + 1,
            skipAhead: 0
        });

        vm.expectRevert(EkuboCore.PoolNotInitialized.selector);
        locker.executeSwap(poolKey, params);
    }

    function testGetLockerState() public {
        // Initially no locker
        DataTypes.LockerState memory state = core.getLockerState(0);
        assertEq(state.locker, address(0));
        assertEq(state.nonzeroDeltaCount, 0);
    }

    function testProtocolFeeCollection() public {
        uint128 initialFees = core.getProtocolFeesCollected(address(token0));
        assertEq(initialFees, 0);
    }

    function testWithdrawProtocolFeesOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert(); // Will revert with Ownable error
        core.withdrawProtocolFees(user1, address(token0), 100);
    }
}
