export interface Token {
  address: string;
  symbol: string;
  name: string;
  decimals: number;
  logoURI?: string;
  chainId: number;
}

export interface TokenAmount {
  token: Token;
  amount: string;
  value?: string; // USD value
}
