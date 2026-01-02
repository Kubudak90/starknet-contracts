// EkuboCore ABI - Simplified for frontend use
export const EkuboCoreABI = [
  {
    "name": "getPoolPrice",
    "type": "function",
    "stateMutability": "view",
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
      }
    ],
    "outputs": [
      {
        "name": "price",
        "type": "tuple",
        "components": [
          { "name": "sqrtPriceX96", "type": "uint256" },
          { "name": "tick", "type": "int128" }
        ]
      }
    ]
  },
  {
    "name": "getPoolLiquidity",
    "type": "function",
    "stateMutability": "view",
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
      }
    ],
    "outputs": [
      { "name": "liquidity", "type": "uint128" }
    ]
  },
  {
    "name": "getPosition",
    "type": "function",
    "stateMutability": "view",
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
        "name": "positionKey",
        "type": "tuple",
        "components": [
          { "name": "owner", "type": "address" },
          { "name": "bounds", "type": "tuple", "components": [
            { "name": "lower", "type": "int128" },
            { "name": "upper", "type": "int128" }
          ]},
          { "name": "salt", "type": "bytes32" }
        ]
      }
    ],
    "outputs": [
      {
        "name": "position",
        "type": "tuple",
        "components": [
          { "name": "liquidity", "type": "uint128" },
          { "name": "feesPerLiquidityInsideInitial0", "type": "uint256" },
          { "name": "feesPerLiquidityInsideInitial1", "type": "uint256" }
        ]
      }
    ]
  },
  {
    "name": "initializePool",
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
      { "name": "initialTick", "type": "int128" }
    ],
    "outputs": [
      { "name": "sqrtPriceX96", "type": "uint256" }
    ]
  }
] as const;
