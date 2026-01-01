import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { mainnet, sepolia, arbitrum, base } from 'wagmi/chains';

export const config = getDefaultConfig({
  appName: 'Ekubo Protocol',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || 'YOUR_PROJECT_ID',
  chains: [mainnet, sepolia, arbitrum, base],
  ssr: true,
});
