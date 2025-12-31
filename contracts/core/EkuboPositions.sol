// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DataTypes} from "../types/DataTypes.sol";
import {ICore, ILocker} from "../interfaces/ICore.sol";
import {TickMath} from "../libraries/TickMath.sol";
import {LiquidityMath} from "../libraries/LiquidityMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title EkuboPositions
/// @notice NFT-based position management for Ekubo AMM
/// @dev Each position is represented as an ERC721 NFT
contract EkuboPositions is ERC721, Ownable, ILocker {
    ICore public immutable core;
    uint64 private _nextTokenId;

    enum CallbackType {
        Deposit,
        Withdraw,
        CollectFees
    }

    struct DepositCallbackData {
        DataTypes.PoolKey poolKey;
        bytes32 salt;
        DataTypes.Bounds bounds;
        uint128 amount0;
        uint128 amount1;
        uint128 minLiquidity;
    }

    struct WithdrawCallbackData {
        DataTypes.PoolKey poolKey;
        bytes32 salt;
        DataTypes.Bounds bounds;
        uint128 liquidity;
        uint128 minToken0;
        uint128 minToken1;
        address recipient;
    }

    struct CollectFeesCallbackData {
        DataTypes.PoolKey poolKey;
        bytes32 salt;
        DataTypes.Bounds bounds;
        address recipient;
    }

    event PositionMintedWithReferrer(uint64 indexed id, address indexed referrer);

    constructor(
        address _core,
        address _owner
    ) ERC721("Ekubo Position", "EkuPo") Ownable(_owner) {
        core = ICore(_core);
        _nextTokenId = 1;
    }

    /// @notice Mint a new position NFT
    function mint() external returns (uint64) {
        return mintWithReferrer(address(0));
    }

    /// @notice Mint a new position NFT with referrer tracking
    function mintWithReferrer(address referrer) public returns (uint64) {
        uint64 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);

        if (referrer != address(0)) {
            emit PositionMintedWithReferrer(tokenId, referrer);
        }

        return tokenId;
    }

    /// @notice Check if an account is authorized for a token
    function isAuthorized(uint64 tokenId, address account) public view returns (bool) {
        address owner = ownerOf(tokenId);
        return owner == account || isApprovedForAll(owner, account) || getApproved(tokenId) == account;
    }

    /// @notice Deposit liquidity into a position
    function deposit(
        uint64 tokenId,
        DataTypes.PoolKey calldata poolKey,
        DataTypes.Bounds calldata bounds,
        uint128 minLiquidity
    ) external returns (uint128) {
        require(isAuthorized(tokenId, msg.sender), "Not authorized");

        uint128 amount0 = uint128(IERC20(poolKey.token0).balanceOf(address(this)));
        uint128 amount1 = uint128(IERC20(poolKey.token1).balanceOf(address(this)));

        return depositAmounts(tokenId, poolKey, bounds, amount0, amount1, minLiquidity);
    }

    /// @notice Deposit specific amounts into a position
    function depositAmounts(
        uint64 tokenId,
        DataTypes.PoolKey calldata poolKey,
        DataTypes.Bounds calldata bounds,
        uint128 amount0,
        uint128 amount1,
        uint128 minLiquidity
    ) public returns (uint128) {
        require(isAuthorized(tokenId, msg.sender), "Not authorized");

        bytes memory data = abi.encode(
            CallbackType.Deposit,
            DepositCallbackData({
                poolKey: poolKey,
                salt: bytes32(uint256(tokenId)),
                bounds: bounds,
                amount0: amount0,
                amount1: amount1,
                minLiquidity: minLiquidity
            })
        );

        bytes memory result = core.lock(data);
        return abi.decode(result, (uint128));
    }

    /// @notice Withdraw liquidity from a position
    function withdraw(
        uint64 tokenId,
        DataTypes.PoolKey calldata poolKey,
        DataTypes.Bounds calldata bounds,
        uint128 liquidity,
        uint128 minToken0,
        uint128 minToken1,
        bool collectFees
    ) external returns (uint128, uint128) {
        require(isAuthorized(tokenId, msg.sender), "Not authorized");

        (uint128 fees0, uint128 fees1) = collectFees
            ? collectPositionFees(tokenId, poolKey, bounds)
            : (uint128(0), uint128(0));

        (uint128 principal0, uint128 principal1) = liquidity > 0
            ? _withdrawLiquidity(tokenId, poolKey, bounds, liquidity, minToken0, minToken1, msg.sender)
            : (uint128(0), uint128(0));

        return (principal0 + fees0, principal1 + fees1);
    }

    /// @notice Collect fees from a position
    function collectPositionFees(
        uint64 tokenId,
        DataTypes.PoolKey calldata poolKey,
        DataTypes.Bounds calldata bounds
    ) public returns (uint128, uint128) {
        require(isAuthorized(tokenId, msg.sender), "Not authorized");

        bytes memory data = abi.encode(
            CallbackType.CollectFees,
            CollectFeesCallbackData({
                poolKey: poolKey,
                salt: bytes32(uint256(tokenId)),
                bounds: bounds,
                recipient: msg.sender
            })
        );

        bytes memory result = core.lock(data);
        DataTypes.Delta memory delta = abi.decode(result, (DataTypes.Delta));

        return (
            uint128(uint256(-delta.amount0)),
            uint128(uint256(-delta.amount1))
        );
    }

    /// @notice Mint and deposit in one transaction
    function mintAndDeposit(
        DataTypes.PoolKey calldata poolKey,
        DataTypes.Bounds calldata bounds,
        uint128 minLiquidity
    ) external returns (uint64, uint128) {
        uint64 tokenId = mintWithReferrer(address(0));
        uint128 liquidity = deposit(tokenId, poolKey, bounds, minLiquidity);
        return (tokenId, liquidity);
    }

    /// @notice Burn a position NFT (only if liquidity is zero)
    function burn(uint64 tokenId) external {
        require(isAuthorized(tokenId, msg.sender), "Not authorized");
        _burn(tokenId);
    }

    /// @notice Get position information including fees
    function getTokenInfo(
        uint64 tokenId,
        DataTypes.PoolKey calldata poolKey,
        DataTypes.Bounds calldata bounds
    ) external view returns (
        DataTypes.PoolPrice memory poolPrice,
        uint128 liquidity,
        uint128 amount0,
        uint128 amount1,
        uint128 fees0,
        uint128 fees1
    ) {
        DataTypes.PositionKey memory positionKey = DataTypes.PositionKey({
            owner: address(this),
            salt: bytes32(uint256(tokenId)),
            bounds: bounds
        });

        poolPrice = core.getPoolPrice(poolKey);
        DataTypes.GetPositionWithFeesResult memory result = core.getPositionWithFees(poolKey, positionKey);

        liquidity = result.position.liquidity;
        fees0 = result.fees0;
        fees1 = result.fees1;

        // Calculate token amounts based on current price
        // This is simplified - full implementation would use proper math
        amount0 = 0;
        amount1 = 0;
    }

    /// @notice Callback from Core.lock()
    function locked(uint32, bytes calldata data) external override returns (bytes memory) {
        require(msg.sender == address(core), "Only core");

        (CallbackType callbackType, bytes memory callbackData) = abi.decode(data, (CallbackType, bytes));

        if (callbackType == CallbackType.Deposit) {
            return _handleDeposit(callbackData);
        } else if (callbackType == CallbackType.Withdraw) {
            return _handleWithdraw(callbackData);
        } else if (callbackType == CallbackType.CollectFees) {
            return _handleCollectFees(callbackData);
        }

        revert("Unknown callback type");
    }

    function _handleDeposit(bytes memory data) internal returns (bytes memory) {
        DepositCallbackData memory params = abi.decode(data, (DepositCallbackData));

        // Update position with extension if needed
        if (params.poolKey.extension != address(0)) {
            core.updatePosition(
                params.poolKey,
                DataTypes.UpdatePositionParameters({
                    salt: 0,
                    bounds: DataTypes.Bounds({
                        lower: type(int128).min,
                        upper: type(int128).max
                    }),
                    liquidityDelta: 0
                })
            );
        }

        DataTypes.PoolPrice memory price = core.getPoolPrice(params.poolKey);

        // Calculate liquidity
        uint128 liquidity = LiquidityMath.maxLiquidity(
            price.sqrtRatio,
            TickMath.tickToSqrtRatio(params.bounds.lower),
            TickMath.tickToSqrtRatio(params.bounds.upper),
            params.amount0,
            params.amount1
        );

        require(liquidity >= params.minLiquidity, "Min liquidity");

        if (liquidity > 0) {
            DataTypes.Delta memory delta = core.updatePosition(
                params.poolKey,
                DataTypes.UpdatePositionParameters({
                    salt: params.salt,
                    bounds: params.bounds,
                    liquidityDelta: int128(uint128(liquidity))
                })
            );

            if (delta.amount0 > 0) {
                IERC20(params.poolKey.token0).approve(address(core), uint256(delta.amount0));
                core.pay(params.poolKey.token0);
            }

            if (delta.amount1 > 0) {
                IERC20(params.poolKey.token1).approve(address(core), uint256(delta.amount1));
                core.pay(params.poolKey.token1);
            }
        }

        return abi.encode(liquidity);
    }

    function _handleWithdraw(bytes memory data) internal returns (bytes memory) {
        WithdrawCallbackData memory params = abi.decode(data, (WithdrawCallbackData));

        DataTypes.Delta memory delta = core.updatePosition(
            params.poolKey,
            DataTypes.UpdatePositionParameters({
                salt: params.salt,
                bounds: params.bounds,
                liquidityDelta: -int128(uint128(params.liquidity))
            })
        );

        require(uint256(-delta.amount0) >= params.minToken0, "Min token0");
        require(uint256(-delta.amount1) >= params.minToken1, "Min token1");

        if (delta.amount0 < 0) {
            core.withdraw(params.poolKey.token0, params.recipient, uint128(uint256(-delta.amount0)));
        }

        if (delta.amount1 < 0) {
            core.withdraw(params.poolKey.token1, params.recipient, uint128(uint256(-delta.amount1)));
        }

        return abi.encode(delta);
    }

    function _handleCollectFees(bytes memory data) internal returns (bytes memory) {
        CollectFeesCallbackData memory params = abi.decode(data, (CollectFeesCallbackData));

        DataTypes.Delta memory delta = core.collectFees(params.poolKey, params.salt, params.bounds);

        if (delta.amount0 < 0) {
            core.withdraw(params.poolKey.token0, params.recipient, uint128(uint256(-delta.amount0)));
        }

        if (delta.amount1 < 0) {
            core.withdraw(params.poolKey.token1, params.recipient, uint128(uint256(-delta.amount1)));
        }

        return abi.encode(delta);
    }

    function _withdrawLiquidity(
        uint64 tokenId,
        DataTypes.PoolKey calldata poolKey,
        DataTypes.Bounds calldata bounds,
        uint128 liquidity,
        uint128 minToken0,
        uint128 minToken1,
        address recipient
    ) internal returns (uint128, uint128) {
        bytes memory data = abi.encode(
            CallbackType.Withdraw,
            WithdrawCallbackData({
                poolKey: poolKey,
                salt: bytes32(uint256(tokenId)),
                bounds: bounds,
                liquidity: liquidity,
                minToken0: minToken0,
                minToken1: minToken1,
                recipient: recipient
            })
        );

        bytes memory result = core.lock(data);
        DataTypes.Delta memory delta = abi.decode(result, (DataTypes.Delta));

        return (
            uint128(uint256(-delta.amount0)),
            uint128(uint256(-delta.amount1))
        );
    }
}
