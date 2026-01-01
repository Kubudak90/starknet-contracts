import { useBalance } from 'wagmi';
import { Token } from '@/lib/types/token';

export function useTokenBalance(address: `0x${string}` | undefined, token: Token | null) {
  const isNativeToken = token?.address === '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';

  return useBalance({
    address,
    token: !isNativeToken && token ? (token.address as `0x${string}`) : undefined,
    enabled: !!address && !!token,
  });
}
