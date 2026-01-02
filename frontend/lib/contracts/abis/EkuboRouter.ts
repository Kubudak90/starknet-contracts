// EkuboRouter ABI - Simplified for frontend use
export const EkuboRouterABI = [
  {
    "name": "swap",
    "type": "function",
    "stateMutability": "nonpayable",
    "inputs": [
      {
        "name": "route",
        "type": "tuple",
        "components": [
          { "name": "poolKey", "type": "bytes32" },
          { "name": "sqrtRatioLimit", "type": "uint256" },
          { "name": "skipAhead", "type": "uint128" }
        ]
      },
      {
        "name": "tokenAmount",
        "type": "tuple",
        "components": [
          { "name": "token", "type": "address" },
          { "name": "amount", "type": "int128" }
        ]
      }
    ],
    "outputs": [
      { "name": "delta0", "type": "int128" },
      { "name": "delta1", "type": "int128" }
    ]
  },
  {
    "name": "multihopSwap",
    "type": "function",
    "stateMutability": "nonpayable",
    "inputs": [
      {
        "name": "route",
        "type": "tuple[]",
        "components": [
          { "name": "poolKey", "type": "bytes32" },
          { "name": "sqrtRatioLimit", "type": "uint256" },
          { "name": "skipAhead", "type": "uint128" }
        ]
      },
      {
        "name": "tokenAmount",
        "type": "tuple",
        "components": [
          { "name": "token", "type": "address" },
          { "name": "amount", "type": "int128" }
        ]
      }
    ],
    "outputs": [
      {
        "name": "deltas",
        "type": "tuple[]",
        "components": [
          { "name": "amount0", "type": "int128" },
          { "name": "amount1", "type": "int128" }
        ]
      }
    ]
  },
  {
    "name": "quoteSwap",
    "type": "function",
    "stateMutability": "view",
    "inputs": [
      {
        "name": "route",
        "type": "tuple",
        "components": [
          { "name": "poolKey", "type": "bytes32" },
          { "name": "sqrtRatioLimit", "type": "uint256" },
          { "name": "skipAhead", "type": "uint128" }
        ]
      },
      {
        "name": "tokenAmount",
        "type": "tuple",
        "components": [
          { "name": "token", "type": "address" },
          { "name": "amount", "type": "int128" }
        ]
      }
    ],
    "outputs": [
      { "name": "delta0", "type": "int128" },
      { "name": "delta1", "type": "int128" }
    ]
  },
  {
    "name": "quoteMultihopSwap",
    "type": "function",
    "stateMutability": "view",
    "inputs": [
      {
        "name": "route",
        "type": "tuple[]",
        "components": [
          { "name": "poolKey", "type": "bytes32" },
          { "name": "sqrtRatioLimit", "type": "uint256" },
          { "name": "skipAhead", "type": "uint128" }
        ]
      },
      {
        "name": "tokenAmount",
        "type": "tuple",
        "components": [
          { "name": "token", "type": "address" },
          { "name": "amount", "type": "int128" }
        ]
      }
    ],
    "outputs": [
      {
        "name": "deltas",
        "type": "tuple[]",
        "components": [
          { "name": "amount0", "type": "int128" },
          { "name": "amount1", "type": "int128" }
        ]
      }
    ]
  }
] as const;
