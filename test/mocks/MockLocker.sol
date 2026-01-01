// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICore, ILocker} from "../../contracts/interfaces/ICore.sol";
import {DataTypes} from "../../contracts/types/DataTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockLocker is ILocker {
    ICore public immutable core;

    // For testing callbacks
    bytes public lastData;
    uint32 public lastId;

    constructor(address _core) {
        core = ICore(_core);
    }

    function locked(uint32 id, bytes calldata data) external override returns (bytes memory) {
        lastId = id;
        lastData = data;

        // Decode and execute the operation
        (string memory operation, bytes memory params) = abi.decode(data, (string, bytes));

        if (keccak256(bytes(operation)) == keccak256(bytes("initializePool"))) {
            (DataTypes.PoolKey memory poolKey, int128 initialTick) = abi.decode(params, (DataTypes.PoolKey, int128));
            core.initializePool(poolKey, initialTick);
        } else if (keccak256(bytes(operation)) == keccak256(bytes("updatePosition"))) {
            (DataTypes.PoolKey memory poolKey, DataTypes.UpdatePositionParameters memory updateParams) =
                abi.decode(params, (DataTypes.PoolKey, DataTypes.UpdatePositionParameters));
            DataTypes.Delta memory delta = core.updatePosition(poolKey, updateParams);

            // Settle deltas
            _settleDelta(id, poolKey.token0, delta.amount0);
            _settleDelta(id, poolKey.token1, delta.amount1);
        } else if (keccak256(bytes(operation)) == keccak256(bytes("swap"))) {
            (DataTypes.PoolKey memory poolKey, DataTypes.SwapParameters memory swapParams) =
                abi.decode(params, (DataTypes.PoolKey, DataTypes.SwapParameters));
            DataTypes.Delta memory delta = core.swap(poolKey, swapParams);

            // Settle deltas
            _settleDelta(id, poolKey.token0, delta.amount0);
            _settleDelta(id, poolKey.token1, delta.amount1);
        }

        return "";
    }

    function _settleDelta(uint32 id, address token, int256 delta) internal {
        if (delta > 0) {
            // We owe tokens to the pool
            IERC20(token).approve(address(core), uint256(delta));
            core.pay(token);
        } else if (delta < 0) {
            // Pool owes tokens to us
            core.withdraw(token, address(this), uint128(uint256(-delta)));
        }
    }

    function executeInitializePool(
        DataTypes.PoolKey calldata poolKey,
        int128 initialTick
    ) external returns (uint256) {
        bytes memory data = abi.encode("initializePool", abi.encode(poolKey, initialTick));
        core.lock(data);
        return 0;
    }

    function executeUpdatePosition(
        DataTypes.PoolKey calldata poolKey,
        DataTypes.UpdatePositionParameters calldata params
    ) external returns (DataTypes.Delta memory) {
        bytes memory data = abi.encode("updatePosition", abi.encode(poolKey, params));
        core.lock(data);
        return DataTypes.Delta(0, 0);
    }

    function executeSwap(
        DataTypes.PoolKey calldata poolKey,
        DataTypes.SwapParameters calldata params
    ) external returns (DataTypes.Delta memory) {
        bytes memory data = abi.encode("swap", abi.encode(poolKey, params));
        core.lock(data);
        return DataTypes.Delta(0, 0);
    }
}
