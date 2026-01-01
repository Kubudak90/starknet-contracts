'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import Link from 'next/link';
import { Waves } from 'lucide-react';

export function Header() {
  return (
    <header className="border-b border-gray-200 dark:border-gray-800">
      <div className="container mx-auto px-4 py-4 flex items-center justify-between">
        <Link href="/" className="flex items-center gap-2 text-xl font-bold">
          <Waves className="w-6 h-6 text-blue-600" />
          <span>Ekubo Protocol</span>
        </Link>

        <nav className="hidden md:flex items-center gap-6">
          <Link href="/swap" className="hover:text-blue-600 transition-colors">
            Swap
          </Link>
          <Link href="/pools" className="hover:text-blue-600 transition-colors">
            Pools
          </Link>
          <Link href="/positions" className="hover:text-blue-600 transition-colors">
            Positions
          </Link>
        </nav>

        <ConnectButton />
      </div>
    </header>
  );
}
