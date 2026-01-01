'use client';

import { Header } from '@/components/Header';
import { motion } from 'framer-motion';
import { ArrowRight, Zap, Shield, Layers } from 'lucide-react';
import Link from 'next/link';

export default function Home() {
  return (
    <div className="min-h-screen">
      <Header />

      <main className="container mx-auto px-4 py-16">
        {/* Hero Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="text-center max-w-4xl mx-auto mb-16"
        >
          <h1 className="text-5xl md:text-6xl font-bold mb-6 bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
            Next-Generation Concentrated Liquidity
          </h1>
          <p className="text-xl text-gray-600 dark:text-gray-400 mb-8">
            EVM-compatible concentrated liquidity DEX with advanced features like TWAMM,
            NFT positions, and gas-optimized trading
          </p>
          <div className="flex gap-4 justify-center">
            <Link
              href="/swap"
              className="px-6 py-3 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition-colors flex items-center gap-2"
            >
              Start Trading
              <ArrowRight className="w-5 h-5" />
            </Link>
            <Link
              href="/pools"
              className="px-6 py-3 border border-gray-300 dark:border-gray-700 rounded-lg font-semibold hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
            >
              Explore Pools
            </Link>
          </div>
        </motion.div>

        {/* Features Grid */}
        <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1 }}
            className="p-6 border border-gray-200 dark:border-gray-800 rounded-xl hover:border-blue-500 dark:hover:border-blue-500 transition-colors"
          >
            <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center mb-4">
              <Zap className="w-6 h-6 text-blue-600" />
            </div>
            <h3 className="text-xl font-semibold mb-2">Gas Optimized</h3>
            <p className="text-gray-600 dark:text-gray-400">
              Bitmap-based tick search and custom errors for maximum gas efficiency
            </p>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            className="p-6 border border-gray-200 dark:border-gray-800 rounded-xl hover:border-blue-500 dark:hover:border-blue-500 transition-colors"
          >
            <div className="w-12 h-12 bg-purple-100 dark:bg-purple-900 rounded-lg flex items-center justify-center mb-4">
              <Shield className="w-6 h-6 text-purple-600" />
            </div>
            <h3 className="text-xl font-semibold mb-2">Secure & Audited</h3>
            <p className="text-gray-600 dark:text-gray-400">
              Locker pattern for reentrancy protection and battle-tested architecture
            </p>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.3 }}
            className="p-6 border border-gray-200 dark:border-gray-800 rounded-xl hover:border-blue-500 dark:hover:border-blue-500 transition-colors"
          >
            <div className="w-12 h-12 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center mb-4">
              <Layers className="w-6 h-6 text-green-600" />
            </div>
            <h3 className="text-xl font-semibold mb-2">Advanced Features</h3>
            <p className="text-gray-600 dark:text-gray-400">
              TWAMM for large orders, extension hooks, and NFT-based positions
            </p>
          </motion.div>
        </div>

        {/* Stats Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.4 }}
          className="mt-16 grid grid-cols-2 md:grid-cols-4 gap-8 max-w-4xl mx-auto"
        >
          <div className="text-center">
            <div className="text-3xl font-bold text-blue-600">$0M</div>
            <div className="text-gray-600 dark:text-gray-400">TVL</div>
          </div>
          <div className="text-center">
            <div className="text-3xl font-bold text-purple-600">$0M</div>
            <div className="text-gray-600 dark:text-gray-400">24h Volume</div>
          </div>
          <div className="text-center">
            <div className="text-3xl font-bold text-green-600">0</div>
            <div className="text-gray-600 dark:text-gray-400">Pools</div>
          </div>
          <div className="text-center">
            <div className="text-3xl font-bold text-orange-600">0</div>
            <div className="text-gray-600 dark:text-gray-400">Users</div>
          </div>
        </motion.div>
      </main>
    </div>
  );
}
