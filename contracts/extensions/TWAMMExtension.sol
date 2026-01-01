// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICore, IExtension} from "../interfaces/ICore.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title TWAMMExtension
/// @notice Time-Weighted Average Market Maker extension for Ekubo Core
/// @dev Allows submission of long-term orders that execute gradually over time
contract TWAMMExtension is IExtension, Ownable {
    ICore public immutable core;

    // Order struct
    struct Order {
        address owner;
        uint256 sellAmount;
        uint256 sellRate; // Amount to sell per second
        uint256 expirationTime;
        bool isToken1; // true if selling token1 for token0
        uint256 filledAmount;
        bool cancelled;
    }

    // Pool orders tracking
    struct PoolOrders {
        uint256 lastExecutionTime;
        uint256 sellRate0For1; // Total rate of token0 being sold for token1
        uint256 sellRate1For0; // Total rate of token1 being sold for token0
    }

    // Storage
    mapping(bytes32 => PoolOrders) public poolOrders; // poolKeyHash => PoolOrders
    mapping(bytes32 => Order) public orders; // orderId => Order
    mapping(bytes32 => uint256[]) public poolOrderIds; // poolKeyHash => orderIds array

    uint256 private nextOrderId = 1;

    // Events
    event OrderSubmitted(
        bytes32 indexed orderId,
        address indexed owner,
        DataTypes.PoolKey poolKey,
        uint256 sellAmount,
        uint256 expirationTime,
        bool isToken1
    );

    event OrderCancelled(bytes32 indexed orderId, uint256 amountRemaining);

    event OrdersExecuted(
        bytes32 indexed poolKeyHash,
        uint256 token0Sold,
        uint256 token1Sold,
        uint256 timestamp
    );

    // Custom errors
    error OrderNotFound();
    error OrderAlreadyCancelled();
    error OrderExpired();
    error NotOrderOwner();
    error InvalidOrderDuration();
    error InvalidSellAmount();
    error PoolNotInitialized();

    constructor(address _core, address _owner) Ownable(_owner) {
        core = ICore(_core);

        // Register call points with core
        DataTypes.CallPoints memory callPoints = DataTypes.CallPoints({
            beforeInitializePool: false,
            afterInitializePool: true,
            beforeUpdatePosition: false,
            afterUpdatePosition: false,
            beforeSwap: true,
            afterSwap: false,
            beforeCollectFees: false,
            afterCollectFees: false
        });

        core.setCallPoints(callPoints);
    }

    /// @notice Submit a long-term order
    /// @param poolKey The pool to trade in
    /// @param sellAmount Total amount to sell
    /// @param duration Duration in seconds over which to execute the order
    /// @param isToken1 True if selling token1 for token0
    /// @return orderId The ID of the created order
    function submitOrder(
        DataTypes.PoolKey calldata poolKey,
        uint256 sellAmount,
        uint256 duration,
        bool isToken1
    ) external returns (bytes32 orderId) {
        if (duration == 0) revert InvalidOrderDuration();
        if (sellAmount == 0) revert InvalidSellAmount();

        bytes32 poolKeyHash = core.getPoolKeyHash(poolKey);
        DataTypes.PoolPrice memory price = core.getPoolPrice(poolKey);
        if (price.sqrtRatio == 0) revert PoolNotInitialized();

        // Calculate sell rate (amount per second)
        uint256 sellRate = sellAmount / duration;
        if (sellRate == 0) revert InvalidSellAmount(); // Amount too small for duration

        // Create order ID
        orderId = keccak256(abi.encodePacked(msg.sender, nextOrderId, block.timestamp));
        unchecked { ++nextOrderId; }

        // Create order
        orders[orderId] = Order({
            owner: msg.sender,
            sellAmount: sellAmount,
            sellRate: sellRate,
            expirationTime: block.timestamp + duration,
            isToken1: isToken1,
            filledAmount: 0,
            cancelled: false
        });

        // Update pool orders
        PoolOrders storage poolOrder = poolOrders[poolKeyHash];
        if (poolOrder.lastExecutionTime == 0) {
            poolOrder.lastExecutionTime = block.timestamp;
        }

        if (isToken1) {
            poolOrder.sellRate1For0 += sellRate;
        } else {
            poolOrder.sellRate0For1 += sellRate;
        }

        // Track order ID for this pool
        poolOrderIds[poolKeyHash].push(uint256(orderId));

        emit OrderSubmitted(orderId, msg.sender, poolKey, sellAmount, block.timestamp + duration, isToken1);

        return orderId;
    }

    /// @notice Cancel an active order
    /// @param orderId The order to cancel
    function cancelOrder(bytes32 orderId) external {
        Order storage order = orders[orderId];
        if (order.owner == address(0)) revert OrderNotFound();
        if (order.owner != msg.sender) revert NotOrderOwner();
        if (order.cancelled) revert OrderAlreadyCancelled();

        order.cancelled = true;
        uint256 amountRemaining = order.sellAmount - order.filledAmount;

        emit OrderCancelled(orderId, amountRemaining);

        // Note: In production, you would transfer the remaining tokens back to the owner
        // This requires integration with the core's token handling
    }

    /// @notice Get order details
    function getOrder(bytes32 orderId) external view returns (Order memory) {
        return orders[orderId];
    }

    /// @notice Get pool orders info
    function getPoolOrders(bytes32 poolKeyHash) external view returns (PoolOrders memory) {
        return poolOrders[poolKeyHash];
    }

    // Extension hooks implementation

    function afterInitializePool(
        address,
        DataTypes.PoolKey calldata poolKey,
        int128
    ) external override {
        require(msg.sender == address(core), "Only core");

        bytes32 poolKeyHash = core.getPoolKeyHash(poolKey);
        poolOrders[poolKeyHash].lastExecutionTime = block.timestamp;
    }

    function beforeSwap(
        address,
        DataTypes.PoolKey calldata poolKey,
        DataTypes.SwapParameters calldata
    ) external override {
        require(msg.sender == address(core), "Only core");

        bytes32 poolKeyHash = core.getPoolKeyHash(poolKey);
        _executeVirtualOrders(poolKeyHash, poolKey);
    }

    /// @notice Execute pending virtual orders for a pool
    /// @dev Called before each swap to ensure TWAMM orders are processed
    function _executeVirtualOrders(
        bytes32 poolKeyHash,
        DataTypes.PoolKey calldata poolKey
    ) internal {
        PoolOrders storage poolOrder = poolOrders[poolKeyHash];

        if (poolOrder.lastExecutionTime == 0) {
            poolOrder.lastExecutionTime = block.timestamp;
            return;
        }

        uint256 timeElapsed = block.timestamp - poolOrder.lastExecutionTime;
        if (timeElapsed == 0) return;

        uint256 amount0ToSell = poolOrder.sellRate0For1 * timeElapsed;
        uint256 amount1ToSell = poolOrder.sellRate1For0 * timeElapsed;

        if (amount0ToSell == 0 && amount1ToSell == 0) return;

        poolOrder.lastExecutionTime = block.timestamp;

        // Execute virtual swaps
        // In production, this would execute actual swaps through the core
        // and distribute proceeds to order owners proportionally

        emit OrdersExecuted(poolKeyHash, amount0ToSell, amount1ToSell, block.timestamp);

        // Clean up expired orders
        _cleanupExpiredOrders(poolKeyHash);
    }

    /// @notice Remove expired orders and update sell rates
    function _cleanupExpiredOrders(bytes32 poolKeyHash) internal {
        uint256[] storage orderIdArray = poolOrderIds[poolKeyHash];
        PoolOrders storage poolOrder = poolOrders[poolKeyHash];

        for (uint256 i = 0; i < orderIdArray.length; ) {
            bytes32 orderId = bytes32(orderIdArray[i]);
            Order storage order = orders[orderId];

            if (order.cancelled || block.timestamp >= order.expirationTime) {
                // Remove this order's rate from pool totals
                if (order.isToken1) {
                    if (poolOrder.sellRate1For0 >= order.sellRate) {
                        poolOrder.sellRate1For0 -= order.sellRate;
                    } else {
                        poolOrder.sellRate1For0 = 0;
                    }
                } else {
                    if (poolOrder.sellRate0For1 >= order.sellRate) {
                        poolOrder.sellRate0For1 -= order.sellRate;
                    } else {
                        poolOrder.sellRate0For1 = 0;
                    }
                }

                // Remove from array (swap with last and pop)
                orderIdArray[i] = orderIdArray[orderIdArray.length - 1];
                orderIdArray.pop();
                // Don't increment i since we need to check the swapped element
            } else {
                unchecked { ++i; }
            }
        }
    }

    // Unused extension hooks (required by interface)
    function beforeInitializePool(address, DataTypes.PoolKey calldata, int128) external pure override {
        revert("Not implemented");
    }

    function beforeUpdatePosition(
        address,
        DataTypes.PoolKey calldata,
        DataTypes.UpdatePositionParameters calldata
    ) external pure override {
        revert("Not implemented");
    }

    function afterUpdatePosition(
        address,
        DataTypes.PoolKey calldata,
        DataTypes.UpdatePositionParameters calldata,
        DataTypes.Delta memory
    ) external pure override {
        revert("Not implemented");
    }

    function afterSwap(
        address,
        DataTypes.PoolKey calldata,
        DataTypes.SwapParameters calldata,
        DataTypes.Delta memory
    ) external pure override {
        revert("Not implemented");
    }

    function beforeCollectFees(
        address,
        DataTypes.PoolKey calldata,
        bytes32,
        DataTypes.Bounds calldata
    ) external pure override {
        revert("Not implemented");
    }

    function afterCollectFees(
        address,
        DataTypes.PoolKey calldata,
        bytes32,
        DataTypes.Bounds calldata,
        DataTypes.Delta memory
    ) external pure override {
        revert("Not implemented");
    }
}
