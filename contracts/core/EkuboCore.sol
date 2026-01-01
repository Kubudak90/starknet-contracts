// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DataTypes} from "../types/DataTypes.sol";
import {ICore, ILocker, IExtension, IForwardee} from "../interfaces/ICore.sol";
import {TickMath} from "../libraries/TickMath.sol";
import {LiquidityMath} from "../libraries/LiquidityMath.sol";
import {SwapMath} from "../libraries/SwapMath.sol";
import {SqrtPriceMath} from "../libraries/SqrtPriceMath.sol";
import {TickBitmap} from "../libraries/TickBitmap.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title EkuboCore
/// @notice Core concentrated liquidity AMM implementation for EVM
/// @dev Adapted from Ekubo Protocol on Starknet
contract EkuboCore is ICore, Ownable, ReentrancyGuard {
    using TickMath for int128;
    using TickMath for uint256;

    // Protocol fee storage (token => collected fees)
    mapping(address => uint128) public protocolFeesCollected;

    // Locker state
    uint32 public lockCount;
    mapping(uint32 => address) private lockerAddresses;
    mapping(uint32 => uint32) private nonzeroDeltaCounts;
    mapping(uint32 => mapping(address => int256)) public lockerTokenDeltas;

    // Pool state
    mapping(bytes32 => DataTypes.PoolPrice) public poolPrices;
    mapping(bytes32 => uint128) public poolLiquidity;
    mapping(bytes32 => DataTypes.FeesPerLiquidity) public poolFees;

    // Tick state
    mapping(bytes32 => mapping(int128 => uint128)) public tickLiquidityNet;
    mapping(bytes32 => mapping(int128 => int128)) public tickLiquidityDelta;
    mapping(bytes32 => mapping(int128 => DataTypes.FeesPerLiquidity)) public tickFeesOutside;
    mapping(bytes32 => mapping(int16 => uint256)) public tickBitmaps;

    // Position state
    mapping(bytes32 => DataTypes.Position) public positions;

    // Saved balances
    mapping(bytes32 => uint128) public savedBalances;

    // Extension call points
    mapping(address => DataTypes.CallPoints) public extensionCallPoints;

    constructor(address _owner) Ownable(_owner) {}

    /// @notice Get pool key hash
    function getPoolKeyHash(DataTypes.PoolKey calldata poolKey) public pure returns (bytes32) {
        return keccak256(abi.encode(poolKey));
    }

    /// @notice Get position key hash
    function getPositionKeyHash(
        DataTypes.PoolKey calldata poolKey,
        DataTypes.PositionKey calldata positionKey
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(poolKey, positionKey));
    }

    /// @notice Get saved balance key hash
    function getSavedBalanceKeyHash(DataTypes.SavedBalanceKey calldata key) public pure returns (bytes32) {
        return keccak256(abi.encode(key));
    }

    // View Functions
    function getProtocolFeesCollected(address token) external view returns (uint128) {
        return protocolFeesCollected[token];
    }

    function getLockerState(uint32 id) external view returns (DataTypes.LockerState memory) {
        return DataTypes.LockerState({
            locker: lockerAddresses[id],
            nonzeroDeltaCount: nonzeroDeltaCounts[id]
        });
    }

    function getLockerDelta(uint32 id, address token) external view returns (int256) {
        return lockerTokenDeltas[id][token];
    }

    function getPoolPrice(DataTypes.PoolKey calldata poolKey) external view returns (DataTypes.PoolPrice memory) {
        return poolPrices[getPoolKeyHash(poolKey)];
    }

    function getPoolLiquidity(DataTypes.PoolKey calldata poolKey) external view returns (uint128) {
        return poolLiquidity[getPoolKeyHash(poolKey)];
    }

    function getPoolFeesPerLiquidity(DataTypes.PoolKey calldata poolKey) external view returns (DataTypes.FeesPerLiquidity memory) {
        return poolFees[getPoolKeyHash(poolKey)];
    }

    function getPoolTickLiquidityDelta(DataTypes.PoolKey calldata poolKey, int128 tick) external view returns (int128) {
        return tickLiquidityDelta[getPoolKeyHash(poolKey)][tick];
    }

    function getPoolTickLiquidityNet(DataTypes.PoolKey calldata poolKey, int128 tick) external view returns (uint128) {
        return tickLiquidityNet[getPoolKeyHash(poolKey)][tick];
    }

    function getPoolTickFeesOutside(DataTypes.PoolKey calldata poolKey, int128 tick) external view returns (DataTypes.FeesPerLiquidity memory) {
        return tickFeesOutside[getPoolKeyHash(poolKey)][tick];
    }

    function getPosition(
        DataTypes.PoolKey calldata poolKey,
        DataTypes.PositionKey calldata positionKey
    ) external view returns (DataTypes.Position memory) {
        return positions[getPositionKeyHash(poolKey, positionKey)];
    }

    function getPositionWithFees(
        DataTypes.PoolKey calldata poolKey,
        DataTypes.PositionKey calldata positionKey
    ) external view returns (DataTypes.GetPositionWithFeesResult memory) {
        bytes32 posKey = getPositionKeyHash(poolKey, positionKey);
        DataTypes.Position memory position = positions[posKey];

        DataTypes.FeesPerLiquidity memory feesPerLiquidityInsideCurrent = _getPoolFeesPerLiquidityInside(
            poolKey,
            positionKey.bounds
        );

        (uint128 fees0, uint128 fees1) = _calculatePositionFees(
            position,
            feesPerLiquidityInsideCurrent
        );

        return DataTypes.GetPositionWithFeesResult({
            position: position,
            fees0: fees0,
            fees1: fees1,
            feesPerLiquidityInsideCurrent: feesPerLiquidityInsideCurrent
        });
    }

    function getSavedBalance(DataTypes.SavedBalanceKey calldata key) external view returns (uint128) {
        return savedBalances[getSavedBalanceKeyHash(key)];
    }

    function nextInitializedTick(
        DataTypes.PoolKey calldata poolKey,
        int128 tick,
        uint128 skipAhead
    ) external view returns (int128, bool) {
        return _nextInitializedTick(getPoolKeyHash(poolKey), poolKey.tickSpacing, tick, skipAhead);
    }

    function prevInitializedTick(
        DataTypes.PoolKey calldata poolKey,
        int128 tick,
        uint128 skipAhead
    ) external view returns (int128, bool) {
        return _prevInitializedTick(getPoolKeyHash(poolKey), poolKey.tickSpacing, tick, skipAhead);
    }

    function getCallPoints(address extension) external view returns (DataTypes.CallPoints memory) {
        return extensionCallPoints[extension];
    }

    // State-Changing Functions

    /// @notice Lock the contract and execute callback
    function lock(bytes calldata data) external nonReentrant returns (bytes memory) {
        uint32 id = lockCount;
        lockCount = id + 1;
        lockerAddresses[id] = msg.sender;

        bytes memory result = ILocker(msg.sender).locked(id, data);

        require(nonzeroDeltaCounts[id] == 0, "Deltas not settled");

        lockCount = id;
        delete lockerAddresses[id];

        return result;
    }

    /// @notice Forward the lock to another contract
    /// @dev Temporarily changes the locker address for the duration of the forwarded call
    function forward(address to, bytes calldata data) external returns (bytes memory) {
        (uint32 id, address locker) = _requireLocker();

        // Update this lock's locker to the forwarded address
        lockerAddresses[id] = to;

        bytes memory result = IForwardee(to).forwarded(locker, id, data);

        // Restore the original locker
        lockerAddresses[id] = locker;

        return result;
    }

    /// @notice Initialize a pool
    function initializePool(
        DataTypes.PoolKey calldata poolKey,
        int128 initialTick
    ) external returns (uint256) {
        _checkPoolKeyValid(poolKey);

        bytes32 poolKeyHash = getPoolKeyHash(poolKey);
        DataTypes.PoolPrice storage price = poolPrices[poolKeyHash];

        require(price.sqrtRatio == 0, "Already initialized");

        // Check extension is registered if present
        if (poolKey.extension != address(0)) {
            require(
                extensionCallPoints[poolKey.extension].beforeInitializePool ||
                extensionCallPoints[poolKey.extension].afterInitializePool,
                "Extension not registered"
            );
        }

        DataTypes.CallPoints memory callPoints = _getCallPointsForCaller(poolKey, msg.sender);

        if (callPoints.beforeInitializePool) {
            IExtension(poolKey.extension).beforeInitializePool(msg.sender, poolKey, initialTick);
        }

        uint256 sqrtRatio = TickMath.tickToSqrtRatio(initialTick);
        price.sqrtRatio = sqrtRatio;
        price.tick = initialTick;

        emit PoolInitialized(poolKey, initialTick, sqrtRatio);

        if (callPoints.afterInitializePool) {
            IExtension(poolKey.extension).afterInitializePool(msg.sender, poolKey, initialTick);
        }

        return sqrtRatio;
    }

    /// @notice Maybe initialize a pool if not already initialized
    function maybeInitializePool(
        DataTypes.PoolKey calldata poolKey,
        int128 initialTick
    ) external returns (bool initialized, uint256 sqrtRatio) {
        bytes32 poolKeyHash = getPoolKeyHash(poolKey);
        DataTypes.PoolPrice storage price = poolPrices[poolKeyHash];

        if (price.sqrtRatio == 0) {
            sqrtRatio = this.initializePool(poolKey, initialTick);
            initialized = true;
        } else {
            sqrtRatio = price.sqrtRatio;
            initialized = false;
        }
    }

    /// @notice Update a position (add or remove liquidity)
    function updatePosition(
        DataTypes.PoolKey calldata poolKey,
        DataTypes.UpdatePositionParameters calldata params
    ) external returns (DataTypes.Delta memory) {
        (uint32 id, address locker) = _requireLocker();

        DataTypes.CallPoints memory callPoints = _getCallPointsForCaller(poolKey, locker);

        if (callPoints.beforeUpdatePosition) {
            IExtension(poolKey.extension).beforeUpdatePosition(locker, poolKey, params);
        }

        // Validate bounds
        _checkBoundsValid(params.bounds, poolKey.tickSpacing);

        bytes32 poolKeyHash = getPoolKeyHash(poolKey);
        DataTypes.PoolPrice storage price = poolPrices[poolKeyHash];
        require(price.sqrtRatio != 0, "Not initialized");

        (uint256 sqrtRatioLower, uint256 sqrtRatioUpper) = (
            TickMath.tickToSqrtRatio(params.bounds.lower),
            TickMath.tickToSqrtRatio(params.bounds.upper)
        );

        // Calculate amount deltas
        (int256 amount0, int256 amount1) = LiquidityMath.liquidityDeltaToAmountDelta(
            price.sqrtRatio,
            params.liquidityDelta,
            sqrtRatioLower,
            sqrtRatioUpper
        );

        DataTypes.Delta memory delta = DataTypes.Delta({
            amount0: amount0,
            amount1: amount1
        });

        // Apply withdrawal fee if removing liquidity
        if (params.liquidityDelta < 0) {
            uint128 fee0 = _computeFee(uint128(uint256(-amount0)), poolKey.fee);
            uint128 fee1 = _computeFee(uint128(uint256(-amount1)), poolKey.fee);

            if (fee0 > 0) {
                protocolFeesCollected[poolKey.token0] += fee0;
                delta.amount0 += int256(uint256(fee0));
            }
            if (fee1 > 0) {
                protocolFeesCollected[poolKey.token1] += fee1;
                delta.amount1 += int256(uint256(fee1));
            }

            DataTypes.PositionKey memory positionKey = DataTypes.PositionKey({
                owner: locker,
                salt: params.salt,
                bounds: params.bounds
            });

            emit ProtocolFeesPaid(poolKey, positionKey, DataTypes.Delta({
                amount0: -int256(uint256(fee0)),
                amount1: -int256(uint256(fee1))
            }));
        }

        // Update position
        _updatePositionState(poolKey, poolKeyHash, locker, params, delta);

        // Update ticks
        _updateTick(poolKeyHash, params.bounds.lower, params.liquidityDelta, false);
        _updateTick(poolKeyHash, params.bounds.upper, params.liquidityDelta, true);

        // Update pool liquidity if position is active
        if (price.tick >= params.bounds.lower && price.tick < params.bounds.upper) {
            uint128 currentLiquidity = poolLiquidity[poolKeyHash];
            poolLiquidity[poolKeyHash] = _addLiquidity(currentLiquidity, params.liquidityDelta);
        }

        _accountPoolDelta(id, poolKey, delta);

        emit PositionUpdated(locker, poolKey, params, delta);

        if (callPoints.afterUpdatePosition) {
            IExtension(poolKey.extension).afterUpdatePosition(locker, poolKey, params, delta);
        }

        return delta;
    }

    /// @notice Collect fees from a position
    function collectFees(
        DataTypes.PoolKey calldata poolKey,
        bytes32 salt,
        DataTypes.Bounds calldata bounds
    ) external returns (DataTypes.Delta memory) {
        (uint32 id, address locker) = _requireLocker();

        DataTypes.CallPoints memory callPoints = _getCallPointsForCaller(poolKey, locker);

        if (callPoints.beforeCollectFees) {
            IExtension(poolKey.extension).beforeCollectFees(locker, poolKey, salt, bounds);
        }

        DataTypes.PositionKey memory positionKey = DataTypes.PositionKey({
            owner: locker,
            salt: salt,
            bounds: bounds
        });

        bytes32 posKey = getPositionKeyHash(poolKey, positionKey);
        DataTypes.Position storage position = positions[posKey];

        DataTypes.FeesPerLiquidity memory feesPerLiquidityInsideCurrent = _getPoolFeesPerLiquidityInside(
            poolKey,
            bounds
        );

        (uint128 fees0, uint128 fees1) = _calculatePositionFees(
            position,
            feesPerLiquidityInsideCurrent
        );

        // Update position
        position.feesPerLiquidityInsideLast = feesPerLiquidityInsideCurrent;

        DataTypes.Delta memory delta = DataTypes.Delta({
            amount0: -int256(uint256(fees0)),
            amount1: -int256(uint256(fees1))
        });

        _accountPoolDelta(id, poolKey, delta);

        emit PositionFeesCollected(poolKey, positionKey, delta);

        if (callPoints.afterCollectFees) {
            IExtension(poolKey.extension).afterCollectFees(locker, poolKey, salt, bounds, delta);
        }

        return delta;
    }

    /// @notice Execute a swap
    function swap(
        DataTypes.PoolKey calldata poolKey,
        DataTypes.SwapParameters calldata params
    ) external returns (DataTypes.Delta memory delta) {
        (uint32 id, address locker) = _requireLocker();

        DataTypes.CallPoints memory callPoints = _getCallPointsForCaller(poolKey, locker);

        if (callPoints.beforeSwap) {
            IExtension(poolKey.extension).beforeSwap(locker, poolKey, params);
        }

        bytes32 poolKeyHash = getPoolKeyHash(poolKey);
        DataTypes.PoolPrice storage price = poolPrices[poolKeyHash];
        require(price.sqrtRatio != 0, "Not initialized");

        // Execute swap logic (simplified - full implementation would be more complex)
        delta = _executeSwap(poolKeyHash, poolKey, price, params);

        _accountPoolDelta(id, poolKey, delta);

        emit Swapped(
            locker,
            poolKey,
            params,
            delta,
            price.sqrtRatio,
            price.tick,
            poolLiquidity[poolKeyHash]
        );

        if (callPoints.afterSwap) {
            IExtension(poolKey.extension).afterSwap(locker, poolKey, params, delta);
        }

        return delta;
    }

    /// @notice Withdraw tokens from the contract
    function withdraw(address token, address recipient, uint128 amount) external {
        (uint32 id, ) = _requireLocker();

        _accountDelta(id, token, int256(uint256(amount)));

        require(
            IERC20(token).transfer(recipient, amount),
            "Transfer failed"
        );
    }

    /// @notice Pay tokens to the contract
    function pay(address token) external {
        (uint32 id, address payer) = _requireLocker();

        IERC20 tokenContract = IERC20(token);
        uint256 allowance = tokenContract.allowance(payer, address(this));
        uint256 balanceBefore = tokenContract.balanceOf(address(this));

        require(
            tokenContract.transferFrom(payer, address(this), allowance),
            "TransferFrom failed"
        );

        uint256 delta = tokenContract.balanceOf(address(this)) - balanceBefore;
        require(delta == allowance, "Transfer invariant");

        _accountDelta(id, token, -int256(delta));
    }

    /// @notice Save balance for later use
    function save(DataTypes.SavedBalanceKey calldata key, uint128 amount) external returns (uint128) {
        (uint32 id, ) = _requireLocker();

        bytes32 keyHash = getSavedBalanceKeyHash(key);
        uint128 saved = savedBalances[keyHash];
        uint128 next = saved + amount;
        savedBalances[keyHash] = next;

        _accountDelta(id, key.token, int256(uint256(amount)));

        emit SavedBalance(key, amount);

        return next;
    }

    /// @notice Load previously saved balance
    function load(address token, bytes32 salt, uint128 amount) external returns (uint128) {
        uint32 id = lockCount > 0 ? lockCount - 1 : 0;
        require(id < lockCount, "Not locked");

        DataTypes.SavedBalanceKey memory key = DataTypes.SavedBalanceKey({
            owner: msg.sender,
            token: token,
            salt: salt
        });

        bytes32 keyHash = getSavedBalanceKeyHash(key);
        uint128 saved = savedBalances[keyHash];
        require(amount <= saved, "Insufficient saved balance");

        uint128 next = saved - amount;
        savedBalances[keyHash] = next;

        _accountDelta(id, token, -int256(uint256(amount)));

        emit LoadedBalance(key, amount);

        return next;
    }

    /// @notice Withdraw protocol fees (owner only)
    function withdrawProtocolFees(
        address recipient,
        address token,
        uint128 amount
    ) external onlyOwner {
        uint128 collected = protocolFeesCollected[token];
        protocolFeesCollected[token] = collected - amount;

        require(IERC20(token).transfer(recipient, amount), "Transfer failed");

        emit ProtocolFeesWithdrawn(recipient, token, amount);
    }

    /// @notice Withdraw all protocol fees for a token (owner only)
    function withdrawAllProtocolFees(
        address recipient,
        address token
    ) external onlyOwner returns (uint128) {
        uint128 amount = protocolFeesCollected[token];
        this.withdrawProtocolFees(recipient, token, amount);
        return amount;
    }

    /// @notice Accumulate tokens as fees (extension only)
    function accumulateAsFees(
        DataTypes.PoolKey calldata poolKey,
        uint128 amount0,
        uint128 amount1
    ) external {
        (uint32 id, address locker) = _requireLocker();
        require(locker == poolKey.extension, "Not extension");

        bytes32 poolKeyHash = getPoolKeyHash(poolKey);
        uint128 liquidity = poolLiquidity[poolKeyHash];

        if (liquidity > 0) {
            DataTypes.FeesPerLiquidity storage fees = poolFees[poolKeyHash];
            if (amount0 > 0) {
                fees.amount0 += (uint256(amount0) << 128) / liquidity;
            }
            if (amount1 > 0) {
                fees.amount1 += (uint256(amount1) << 128) / liquidity;
            }
        }

        _accountPoolDelta(id, poolKey, DataTypes.Delta({
            amount0: int256(uint256(amount0)),
            amount1: int256(uint256(amount1))
        }));

        emit FeesAccumulated(poolKey, amount0, amount1);
    }

    /// @notice Set call points for an extension
    function setCallPoints(DataTypes.CallPoints calldata callPoints) external {
        require(
            callPoints.beforeInitializePool ||
            callPoints.afterInitializePool ||
            callPoints.beforeUpdatePosition ||
            callPoints.afterUpdatePosition ||
            callPoints.beforeSwap ||
            callPoints.afterSwap ||
            callPoints.beforeCollectFees ||
            callPoints.afterCollectFees,
            "Invalid call points"
        );

        extensionCallPoints[msg.sender] = callPoints;
    }

    // Internal helper functions

    function _requireLocker() internal view returns (uint32 id, address locker) {
        require(lockCount > 0, "Not locked");
        id = lockCount - 1;
        locker = lockerAddresses[id];
        require(locker == msg.sender, "Not locker");
    }

    function _accountDelta(uint32 id, address token, int256 delta) internal {
        int256 current = lockerTokenDeltas[id][token];
        int256 next = current + delta;
        lockerTokenDeltas[id][token] = next;

        bool currentIsZero = current == 0;
        bool nextIsZero = next == 0;

        if (currentIsZero != nextIsZero) {
            if (nextIsZero) {
                nonzeroDeltaCounts[id]--;
            } else {
                nonzeroDeltaCounts[id]++;
            }
        }
    }

    function _accountPoolDelta(
        uint32 id,
        DataTypes.PoolKey calldata poolKey,
        DataTypes.Delta memory delta
    ) internal {
        _accountDelta(id, poolKey.token0, delta.amount0);
        _accountDelta(id, poolKey.token1, delta.amount1);
    }

    function _checkPoolKeyValid(DataTypes.PoolKey calldata poolKey) internal pure {
        require(poolKey.token0 < poolKey.token1, "Invalid token order");
        require(poolKey.token0 != address(0), "Token cannot be zero");
        require(
            poolKey.tickSpacing > 0 && poolKey.tickSpacing <= TickMath.MAX_TICK_SPACING,
            "Invalid tick spacing"
        );
    }

    function _checkBoundsValid(DataTypes.Bounds calldata bounds, uint128 tickSpacing) internal pure {
        require(bounds.lower < bounds.upper, "Invalid bounds order");
        require(bounds.lower >= TickMath.MIN_TICK, "Lower bound too low");
        require(bounds.upper <= TickMath.MAX_TICK, "Upper bound too high");
        require(
            uint128(bounds.lower >= 0 ? bounds.lower : -bounds.lower) % tickSpacing == 0 &&
            uint128(bounds.upper >= 0 ? bounds.upper : -bounds.upper) % tickSpacing == 0,
            "Bounds not aligned to tick spacing"
        );
    }

    function _getCallPointsForCaller(
        DataTypes.PoolKey calldata poolKey,
        address caller
    ) internal view returns (DataTypes.CallPoints memory) {
        if (poolKey.extension != address(0) && poolKey.extension != caller) {
            return extensionCallPoints[poolKey.extension];
        }
        return DataTypes.CallPoints({
            beforeInitializePool: false,
            afterInitializePool: false,
            beforeUpdatePosition: false,
            afterUpdatePosition: false,
            beforeSwap: false,
            afterSwap: false,
            beforeCollectFees: false,
            afterCollectFees: false
        });
    }

    function _getPoolFeesPerLiquidityInside(
        DataTypes.PoolKey calldata poolKey,
        DataTypes.Bounds calldata bounds
    ) internal view returns (DataTypes.FeesPerLiquidity memory) {
        bytes32 poolKeyHash = getPoolKeyHash(poolKey);
        DataTypes.PoolPrice storage price = poolPrices[poolKeyHash];

        DataTypes.FeesPerLiquidity memory feesOutsideLower = tickFeesOutside[poolKeyHash][bounds.lower];
        DataTypes.FeesPerLiquidity memory feesOutsideUpper = tickFeesOutside[poolKeyHash][bounds.upper];
        DataTypes.FeesPerLiquidity memory poolFeesPerLiq = poolFees[poolKeyHash];

        if (price.tick < bounds.lower) {
            return DataTypes.FeesPerLiquidity({
                amount0: feesOutsideLower.amount0 - feesOutsideUpper.amount0,
                amount1: feesOutsideLower.amount1 - feesOutsideUpper.amount1
            });
        } else if (price.tick < bounds.upper) {
            return DataTypes.FeesPerLiquidity({
                amount0: poolFeesPerLiq.amount0 - feesOutsideLower.amount0 - feesOutsideUpper.amount0,
                amount1: poolFeesPerLiq.amount1 - feesOutsideLower.amount1 - feesOutsideUpper.amount1
            });
        } else {
            return DataTypes.FeesPerLiquidity({
                amount0: feesOutsideUpper.amount0 - feesOutsideLower.amount0,
                amount1: feesOutsideUpper.amount1 - feesOutsideLower.amount1
            });
        }
    }

    function _calculatePositionFees(
        DataTypes.Position memory position,
        DataTypes.FeesPerLiquidity memory feesPerLiquidityInsideCurrent
    ) internal pure returns (uint128 fees0, uint128 fees1) {
        if (position.liquidity == 0) {
            return (0, 0);
        }

        uint256 feeGrowth0 = feesPerLiquidityInsideCurrent.amount0 - position.feesPerLiquidityInsideLast.amount0;
        uint256 feeGrowth1 = feesPerLiquidityInsideCurrent.amount1 - position.feesPerLiquidityInsideLast.amount1;

        fees0 = uint128((feeGrowth0 * position.liquidity) >> 128);
        fees1 = uint128((feeGrowth1 * position.liquidity) >> 128);
    }

    function _updatePositionState(
        DataTypes.PoolKey calldata poolKey,
        bytes32 poolKeyHash,
        address locker,
        DataTypes.UpdatePositionParameters calldata params,
        DataTypes.Delta memory delta
    ) internal {
        DataTypes.PositionKey memory positionKey = DataTypes.PositionKey({
            owner: locker,
            salt: params.salt,
            bounds: params.bounds
        });

        bytes32 posKey = getPositionKeyHash(poolKey, positionKey);
        DataTypes.Position storage position = positions[posKey];

        DataTypes.FeesPerLiquidity memory feesPerLiquidityInsideCurrent = _getPoolFeesPerLiquidityInside(
            poolKey,
            params.bounds
        );

        (uint128 fees0, uint128 fees1) = _calculatePositionFees(position, feesPerLiquidityInsideCurrent);

        uint128 nextLiquidity = _addLiquidity(position.liquidity, params.liquidityDelta);

        if (nextLiquidity > 0) {
            position.liquidity = nextLiquidity;
            position.feesPerLiquidityInsideLast = DataTypes.FeesPerLiquidity({
                amount0: feesPerLiquidityInsideCurrent.amount0 - ((uint256(fees0) << 128) / nextLiquidity),
                amount1: feesPerLiquidityInsideCurrent.amount1 - ((uint256(fees1) << 128) / nextLiquidity)
            });
        } else {
            require(fees0 == 0 && fees1 == 0, "Must collect fees");
            delete positions[posKey];
        }
    }

    function _updateTick(
        bytes32 poolKeyHash,
        int128 tick,
        int128 liquidityDelta,
        bool isUpper
    ) internal {
        int128 currentDelta = tickLiquidityDelta[poolKeyHash][tick];
        uint128 currentNet = tickLiquidityNet[poolKeyHash][tick];

        int128 nextDelta = isUpper ? currentDelta - liquidityDelta : currentDelta + liquidityDelta;
        uint128 nextNet = _addLiquidity(currentNet, liquidityDelta);

        tickLiquidityDelta[poolKeyHash][tick] = nextDelta;
        tickLiquidityNet[poolKeyHash][tick] = nextNet;

        // Update bitmap
        bool wasInitialized = currentNet != 0;
        bool isInitialized = nextNet != 0;

        if (wasInitialized != isInitialized) {
            _flipTickInBitmap(poolKeyHash, tick, int24(uint24(tickSpacing)));
        }
    }

    function _flipTickInBitmap(
        bytes32 poolKeyHash,
        int128 tick,
        int24 tickSpacing
    ) internal {
        TickBitmap.flipTick(
            tickBitmaps[poolKeyHash],
            int24(tick),
            tickSpacing
        );
    }

    function _addLiquidity(uint128 liquidity, int128 delta) internal pure returns (uint128) {
        if (delta >= 0) {
            return liquidity + uint128(delta);
        } else {
            return liquidity - uint128(-delta);
        }
    }

    function _computeFee(uint128 amount, uint128 feeRate) internal pure returns (uint128) {
        return uint128((uint256(amount) * feeRate) >> 128);
    }

    function _executeSwap(
        bytes32 poolKeyHash,
        DataTypes.PoolKey calldata poolKey,
        DataTypes.PoolPrice storage price,
        DataTypes.SwapParameters calldata params
    ) internal returns (DataTypes.Delta memory) {
        bool increasing = SwapMath.isPriceIncreasing(params.amount < 0, params.isToken1);

        // Validate limit direction
        require((params.sqrtRatioLimit > price.sqrtRatio) == increasing, "LIMIT_DIRECTION");
        require(
            params.sqrtRatioLimit >= TickMath.MIN_SQRT_RATIO &&
            params.sqrtRatioLimit <= TickMath.MAX_SQRT_RATIO,
            "LIMIT_MAG"
        );

        int128 tick = price.tick;
        int256 amountRemaining = params.amount;
        uint256 sqrtRatio = price.sqrtRatio;
        uint128 liquidity = poolLiquidity[poolKeyHash];
        uint128 calculatedAmount = 0;

        DataTypes.FeesPerLiquidity memory feesPerLiq = poolFees[poolKeyHash];

        // Main swap loop
        while (amountRemaining != 0 && sqrtRatio != params.sqrtRatioLimit) {
            // Find next initialized tick
            (int128 nextTick, bool isInitialized) = increasing
                ? _nextInitializedTick(poolKeyHash, poolKey.tickSpacing, tick, params.skipAhead)
                : _prevInitializedTick(poolKeyHash, poolKey.tickSpacing, tick, params.skipAhead);

            uint256 nextTickSqrtRatio = TickMath.tickToSqrtRatio(nextTick);

            // Determine step limit
            uint256 stepSqrtRatioLimit = increasing
                ? (params.sqrtRatioLimit < nextTickSqrtRatio ? params.sqrtRatioLimit : nextTickSqrtRatio)
                : (params.sqrtRatioLimit > nextTickSqrtRatio ? params.sqrtRatioLimit : nextTickSqrtRatio);

            // Execute swap step
            SwapMath.SwapResult memory swapResult = SwapMath.computeSwapStep(
                sqrtRatio,
                liquidity,
                stepSqrtRatioLimit,
                amountRemaining,
                params.isToken1,
                poolKey.fee
            );

            // Accumulate fees
            if (swapResult.feeAmount > 0 && liquidity > 0) {
                uint256 feeGrowth = (uint256(swapResult.feeAmount) << 128) / liquidity;
                if (increasing) {
                    feesPerLiq.amount1 += feeGrowth;
                } else {
                    feesPerLiq.amount0 += feeGrowth;
                }
            }

            amountRemaining -= swapResult.consumedAmount;
            calculatedAmount += swapResult.calculatedAmount;

            // Check if we crossed a tick
            if (swapResult.sqrtRatioNext == nextTickSqrtRatio) {
                sqrtRatio = swapResult.sqrtRatioNext;
                tick = increasing ? nextTick : nextTick - 1;

                // Cross the tick if initialized
                if (isInitialized) {
                    int128 liquidityDelta = tickLiquidityDelta[poolKeyHash][nextTick];

                    if (increasing) {
                        liquidity = _addLiquidity(liquidity, liquidityDelta);
                    } else {
                        liquidity = _addLiquidity(liquidity, -liquidityDelta);
                    }

                    // Update tick fees outside
                    DataTypes.FeesPerLiquidity storage feesOutside = tickFeesOutside[poolKeyHash][nextTick];
                    if (increasing) {
                        feesOutside.amount0 = feesPerLiq.amount0 - feesOutside.amount0;
                        feesOutside.amount1 = feesPerLiq.amount1 - feesOutside.amount1;
                    } else {
                        feesOutside.amount0 = feesPerLiq.amount0 - feesOutside.amount0;
                        feesOutside.amount1 = feesPerLiq.amount1 - feesOutside.amount1;
                    }
                }
            } else {
                // Didn't cross tick, just update price
                sqrtRatio = swapResult.sqrtRatioNext;
                tick = TickMath.sqrtRatioToTick(sqrtRatio);
            }
        }

        // Update pool state
        price.sqrtRatio = sqrtRatio;
        price.tick = tick;
        poolLiquidity[poolKeyHash] = liquidity;
        poolFees[poolKeyHash] = feesPerLiq;

        // Calculate final delta
        DataTypes.Delta memory delta;
        if (params.isToken1) {
            delta.amount0 = -int256(uint256(calculatedAmount));
            delta.amount1 = params.amount - amountRemaining;
        } else {
            delta.amount0 = params.amount - amountRemaining;
            delta.amount1 = -int256(uint256(calculatedAmount));
        }

        return delta;
    }

    function _nextInitializedTick(
        bytes32 poolKeyHash,
        uint128 tickSpacing,
        int128 tick,
        uint128 skipAhead
    ) internal view returns (int128, bool) {
        int24 tickSpacing24 = int24(uint24(tickSpacing));
        int24 currentTick = int24(tick);

        // Skip ahead if requested
        if (skipAhead > 0) {
            currentTick += int24(uint24(skipAhead)) * tickSpacing24;
            if (currentTick > int24(TickMath.MAX_TICK)) {
                return (TickMath.MAX_TICK, false);
            }
        }

        // Search up to 256 words (65536 ticks per word * 256 = ~16M ticks)
        for (uint256 i = 0; i < 256; i++) {
            (int24 next, bool initialized) = TickBitmap.nextInitializedTickWithinOneWord(
                tickBitmaps[poolKeyHash],
                currentTick,
                tickSpacing24,
                false // lte = false means search forward
            );

            if (initialized) {
                return (int128(next), true);
            }

            // Move to next word
            currentTick = next + tickSpacing24;
            if (currentTick > int24(TickMath.MAX_TICK)) {
                break;
            }
        }

        return (TickMath.MAX_TICK, false);
    }

    function _prevInitializedTick(
        bytes32 poolKeyHash,
        uint128 tickSpacing,
        int128 tick,
        uint128 skipAhead
    ) internal view returns (int128, bool) {
        int24 tickSpacing24 = int24(uint24(tickSpacing));
        int24 currentTick = int24(tick);

        // Skip ahead (backwards) if requested
        if (skipAhead > 0) {
            currentTick -= int24(uint24(skipAhead)) * tickSpacing24;
            if (currentTick < int24(TickMath.MIN_TICK)) {
                return (TickMath.MIN_TICK, false);
            }
        }

        // Search up to 256 words backwards
        for (uint256 i = 0; i < 256; i++) {
            (int24 prev, bool initialized) = TickBitmap.nextInitializedTickWithinOneWord(
                tickBitmaps[poolKeyHash],
                currentTick,
                tickSpacing24,
                true // lte = true means search backward
            );

            if (initialized) {
                return (int128(prev), true);
            }

            // Move to previous word
            currentTick = prev - tickSpacing24;
            if (currentTick < int24(TickMath.MIN_TICK)) {
                break;
            }
        }

        return (TickMath.MIN_TICK, false);
    }
}
