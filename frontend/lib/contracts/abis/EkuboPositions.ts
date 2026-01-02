// EkuboPositions ABI - Simplified for frontend use
export const EkuboPositionsABI = [
  {
    "name": "mintAndDeposit",
    "type": "function",
    "stateMutability": "nonpayable",
    "inputs": [
      {
        "name": "poolKey",
        "type": "tuple",
        "components": [
          { "name": "token0", "type": "address" },
          { "name": "token1", "type": "address" },
          { "name": "fee", "type": "uint24" },
          { "name": "tickSpacing", "type": "int24" },
          { "name": "extension", "type": "address" }
        ]
      },
      {
        "name": "bounds",
        "type": "tuple",
        "components": [
          { "name": "lower", "type": "int128" },
          { "name": "upper", "type": "int128" }
        ]
      },
      { "name": "minLiquidity", "type": "uint128" }
    ],
    "outputs": [
      { "name": "tokenId", "type": "uint256" },
      { "name": "liquidity", "type": "uint128" }
    ]
  },
  {
    "name": "deposit",
    "type": "function",
    "stateMutability": "nonpayable",
    "inputs": [
      { "name": "tokenId", "type": "uint256" },
      {
        "name": "poolKey",
        "type": "tuple",
        "components": [
          { "name": "token0", "type": "address" },
          { "name": "token1", "type": "address" },
          { "name": "fee", "type": "uint24" },
          { "name": "tickSpacing", "type": "int24" },
          { "name": "extension", "type": "address" }
        ]
      },
      {
        "name": "bounds",
        "type": "tuple",
        "components": [
          { "name": "lower", "type": "int128" },
          { "name": "upper", "type": "int128" }
        ]
      },
      { "name": "minLiquidity", "type": "uint128" }
    ],
    "outputs": [
      { "name": "liquidity", "type": "uint128" }
    ]
  },
  {
    "name": "withdraw",
    "type": "function",
    "stateMutability": "nonpayable",
    "inputs": [
      { "name": "tokenId", "type": "uint256" },
      {
        "name": "poolKey",
        "type": "tuple",
        "components": [
          { "name": "token0", "type": "address" },
          { "name": "token1", "type": "address" },
          { "name": "fee", "type": "uint24" },
          { "name": "tickSpacing", "type": "int24" },
          { "name": "extension", "type": "address" }
        ]
      },
      {
        "name": "bounds",
        "type": "tuple",
        "components": [
          { "name": "lower", "type": "int128" },
          { "name": "upper", "type": "int128" }
        ]
      },
      { "name": "liquidity", "type": "uint128" },
      { "name": "minToken0", "type": "uint128" },
      { "name": "minToken1", "type": "uint128" }
    ],
    "outputs": [
      { "name": "amount0", "type": "uint128" },
      { "name": "amount1", "type": "uint128" }
    ]
  },
  {
    "name": "collectFees",
    "type": "function",
    "stateMutability": "nonpayable",
    "inputs": [
      { "name": "tokenId", "type": "uint256" },
      {
        "name": "poolKey",
        "type": "tuple",
        "components": [
          { "name": "token0", "type": "address" },
          { "name": "token1", "type": "address" },
          { "name": "fee", "type": "uint24" },
          { "name": "tickSpacing", "type": "int24" },
          { "name": "extension", "type": "address" }
        ]
      },
      {
        "name": "bounds",
        "type": "tuple",
        "components": [
          { "name": "lower", "type": "int128" },
          { "name": "upper", "type": "int128" }
        ]
      }
    ],
    "outputs": [
      { "name": "amount0", "type": "uint128" },
      { "name": "amount1", "type": "uint128" }
    ]
  },
  {
    "name": "getTokenInfo",
    "type": "function",
    "stateMutability": "view",
    "inputs": [
      { "name": "tokenId", "type": "uint256" },
      {
        "name": "poolKey",
        "type": "tuple",
        "components": [
          { "name": "token0", "type": "address" },
          { "name": "token1", "type": "address" },
          { "name": "fee", "type": "uint24" },
          { "name": "tickSpacing", "type": "int24" },
          { "name": "extension", "type": "address" }
        ]
      },
      {
        "name": "bounds",
        "type": "tuple",
        "components": [
          { "name": "lower", "type": "int128" },
          { "name": "upper", "type": "int128" }
        ]
      }
    ],
    "outputs": [
      {
        "name": "info",
        "type": "tuple",
        "components": [
          { "name": "sqrtPriceX96", "type": "uint256" },
          { "name": "liquidity", "type": "uint128" },
          { "name": "amount0", "type": "uint128" },
          { "name": "amount1", "type": "uint128" },
          { "name": "fees0", "type": "uint128" },
          { "name": "fees1", "type": "uint128" }
        ]
      }
    ]
  },
  {
    "name": "mint",
    "type": "function",
    "stateMutability": "nonpayable",
    "inputs": [
      { "name": "referrer", "type": "address" }
    ],
    "outputs": [
      { "name": "tokenId", "type": "uint256" }
    ]
  }
] as const;
