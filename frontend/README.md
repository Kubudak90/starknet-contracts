# Ekubo Protocol Frontend

Modern Web3 frontend for Ekubo Protocol - a concentrated liquidity AMM on EVM-compatible chains.

## Tech Stack

### Core
- **TypeScript** - Type-safe development
- **Next.js 15** (App Router) - React framework with server components
- **React 19** - UI library

### Web3 Integration
- **Wagmi** - React Hooks for Ethereum
- **Viem** - TypeScript Ethereum interface
- **RainbowKit** - Beautiful wallet connection UI

### Styling & UI
- **Tailwind CSS** - Utility-first CSS framework
- **Framer Motion** - Animation library
- **Radix UI** - Accessible component primitives
- **Lucide React** - Icon library

### Data Management
- **TanStack Query (React Query)** - Async state management
- **The Graph** (planned) - Blockchain data indexing

## Getting Started

### Prerequisites

- Node.js 18+ and npm
- A WalletConnect Project ID from [WalletConnect Cloud](https://cloud.walletconnect.com/)

### Installation

1. Install dependencies:
```bash
npm install
```

2. Create environment file:
```bash
cp .env.example .env
```

3. Update `.env` with your configuration:
```env
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id_here
NEXT_PUBLIC_EKUBO_CORE_ADDRESS=0x...
NEXT_PUBLIC_EKUBO_POSITIONS_ADDRESS=0x...
NEXT_PUBLIC_EKUBO_ROUTER_ADDRESS=0x...
```

### Development

Run the development server:
```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Build

```bash
npm run build
npm start
```

## Project Structure

```
frontend/
├── app/                    # Next.js App Router
│   ├── layout.tsx         # Root layout with providers
│   ├── page.tsx           # Home page
│   ├── globals.css        # Global styles
│   └── providers.tsx      # Web3 providers
├── components/            # React components
│   └── Header.tsx         # Navigation header
├── config/                # Configuration files
│   └── wagmi.ts          # Wagmi/RainbowKit config
├── lib/                   # Utility functions
├── public/               # Static assets
└── next.config.js        # Next.js configuration
```

## Features

- ✅ Wallet connection with RainbowKit
- ✅ Multi-chain support (Ethereum, Arbitrum, Base, Sepolia)
- ✅ Dark mode support
- ✅ Responsive design
- ✅ Type-safe smart contract interactions
- 🚧 Swap interface (coming soon)
- 🚧 Liquidity pool management (coming soon)
- 🚧 NFT position viewer (coming soon)

## Development Roadmap

### Phase 1: Core Infrastructure ✅
- [x] Next.js setup with TypeScript
- [x] Web3 integration (Wagmi + RainbowKit)
- [x] UI library setup (Tailwind + Radix)
- [x] Basic layout and navigation

### Phase 2: Trading Features 🚧
- [ ] Swap interface
- [ ] Token selection
- [ ] Price impact calculation
- [ ] Slippage settings
- [ ] Transaction history

### Phase 3: Liquidity Management 🚧
- [ ] Pool explorer
- [ ] Add liquidity interface
- [ ] Remove liquidity
- [ ] Position NFT viewer
- [ ] Fee collection

### Phase 4: Advanced Features 📋
- [ ] TWAMM order interface
- [ ] Analytics dashboard
- [ ] The Graph integration
- [ ] Advanced charts
- [ ] Portfolio tracking

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT
