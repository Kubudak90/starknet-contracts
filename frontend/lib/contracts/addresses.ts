// Ekubo Protocol Contract Addresses
// TODO: Update these addresses after deployment

export interface ContractAddresses {
  core: `0x${string}`;
  positions: `0x${string}`;
  router: `0x${string}`;
}

// Mainnet (Ethereum)
export const MAINNET_ADDRESSES: ContractAddresses = {
  core: '0x0000000000000000000000000000000000000001',
  positions: '0x0000000000000000000000000000000000000002',
  router: '0x0000000000000000000000000000000000000003',
};

// Sepolia Testnet
export const SEPOLIA_ADDRESSES: ContractAddresses = {
  core: '0x0000000000000000000000000000000000000001',
  positions: '0x0000000000000000000000000000000000000002',
  router: '0x0000000000000000000000000000000000000003',
};

// Arbitrum One
export const ARBITRUM_ADDRESSES: ContractAddresses = {
  core: '0x0000000000000000000000000000000000000001',
  positions: '0x0000000000000000000000000000000000000002',
  router: '0x0000000000000000000000000000000000000003',
};

// Base
export const BASE_ADDRESSES: ContractAddresses = {
  core: '0x0000000000000000000000000000000000000001',
  positions: '0x0000000000000000000000000000000000000002',
  router: '0x0000000000000000000000000000000000000003',
};

export const ADDRESSES_BY_CHAIN: Record<number, ContractAddresses> = {
  1: MAINNET_ADDRESSES,           // Ethereum Mainnet
  11155111: SEPOLIA_ADDRESSES,    // Sepolia Testnet
  42161: ARBITRUM_ADDRESSES,      // Arbitrum One
  8453: BASE_ADDRESSES,           // Base
};

export function getContractAddresses(chainId: number): ContractAddresses {
  return ADDRESSES_BY_CHAIN[chainId] || SEPOLIA_ADDRESSES;
}
