'use client';

import { useState, useMemo } from 'react';
import { Header } from '@/components/Header';
import { PositionCard } from '@/components/positions/PositionCard';
import { PositionDetailsModal } from '@/components/positions/PositionDetailsModal';
import { PoolPosition } from '@/lib/types/pool';
import { getMockPositionsByChainId, isInRange, getTotalUnclaimedFeesUSD } from '@/lib/constants/positions';
import { formatCurrency } from '@/lib/utils/format';
import { Wallet, TrendingUp, DollarSign, Layers, Plus } from 'lucide-react';
import { useAccount, useChainId } from 'wagmi';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { motion } from 'framer-motion';
import Link from 'next/link';

export default function PositionsPage() {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const [selectedPosition, setSelectedPosition] = useState<PoolPosition | null>(null);
  const [isDetailsOpen, setIsDetailsOpen] = useState(false);
  const [showInactive, setShowInactive] = useState(true);

  const allPositions = getMockPositionsByChainId(chainId);

  // Filter positions
  const filteredPositions = useMemo(() => {
    if (showInactive) return allPositions;
    return allPositions.filter((position) => isInRange(position));
  }, [allPositions, showInactive]);

  // Calculate stats
  const totalValue = allPositions.reduce((sum, position) => sum + position.valueUSD, 0);
  const totalFees = allPositions.reduce((sum, position) => sum + getTotalUnclaimedFeesUSD(position), 0);
  const activePositions = allPositions.filter((position) => isInRange(position)).length;

  const handleViewDetails = (position: PoolPosition) => {
    setSelectedPosition(position);
    setIsDetailsOpen(true);
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-50 to-gray-100 dark:from-gray-900 dark:to-gray-950">
      <Header />

      <main className="container mx-auto px-4 py-8">
        {/* Page Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-8"
        >
          <h1 className="text-4xl font-bold mb-2">My Positions</h1>
          <p className="text-gray-600 dark:text-gray-400">
            Manage your liquidity positions and collect fees
          </p>
        </motion.div>

        {!isConnected ? (
          /* Not Connected State */
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="max-w-2xl mx-auto text-center py-16"
          >
            <div className="w-24 h-24 mx-auto mb-6 bg-gradient-to-br from-blue-500 to-purple-500 rounded-full flex items-center justify-center">
              <Wallet className="w-12 h-12 text-white" />
            </div>
            <h2 className="text-2xl font-bold mb-4">Connect Your Wallet</h2>
            <p className="text-gray-600 dark:text-gray-400 mb-8">
              Connect your wallet to view and manage your liquidity positions
            </p>
            <ConnectButton />
          </motion.div>
        ) : allPositions.length === 0 ? (
          /* No Positions State */
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="max-w-2xl mx-auto text-center py-16"
          >
            <div className="text-6xl mb-4">🏊‍♂️</div>
            <h2 className="text-2xl font-bold mb-4">No Positions Yet</h2>
            <p className="text-gray-600 dark:text-gray-400 mb-8">
              Start providing liquidity to earn trading fees
            </p>
            <Link
              href="/pools"
              className="inline-flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white rounded-xl font-semibold transition-all"
            >
              <Plus className="w-5 h-5" />
              Add Liquidity
            </Link>
          </motion.div>
        ) : (
          <>
            {/* Stats Cards */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.1 }}
                className="bg-white dark:bg-gray-900 rounded-2xl p-6 border border-gray-200 dark:border-gray-800"
              >
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm text-gray-600 dark:text-gray-400">Total Value</span>
                  <div className="p-2 bg-blue-100 dark:bg-blue-900/20 rounded-lg">
                    <DollarSign className="w-5 h-5 text-blue-600" />
                  </div>
                </div>
                <div className="text-2xl font-bold">{formatCurrency(totalValue)}</div>
              </motion.div>

              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
                className="bg-white dark:bg-gray-900 rounded-2xl p-6 border border-gray-200 dark:border-gray-800"
              >
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm text-gray-600 dark:text-gray-400">Unclaimed Fees</span>
                  <div className="p-2 bg-green-100 dark:bg-green-900/20 rounded-lg">
                    <TrendingUp className="w-5 h-5 text-green-600" />
                  </div>
                </div>
                <div className="text-2xl font-bold text-green-600">{formatCurrency(totalFees)}</div>
              </motion.div>

              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 }}
                className="bg-white dark:bg-gray-900 rounded-2xl p-6 border border-gray-200 dark:border-gray-800"
              >
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm text-gray-600 dark:text-gray-400">Active Positions</span>
                  <div className="p-2 bg-purple-100 dark:bg-purple-900/20 rounded-lg">
                    <Layers className="w-5 h-5 text-purple-600" />
                  </div>
                </div>
                <div className="text-2xl font-bold">{activePositions}</div>
              </motion.div>

              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4 }}
                className="bg-white dark:bg-gray-900 rounded-2xl p-6 border border-gray-200 dark:border-gray-800"
              >
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm text-gray-600 dark:text-gray-400">Total Positions</span>
                  <div className="p-2 bg-orange-100 dark:bg-orange-900/20 rounded-lg">
                    <Wallet className="w-5 h-5 text-orange-600" />
                  </div>
                </div>
                <div className="text-2xl font-bold">{allPositions.length}</div>
              </motion.div>
            </div>

            {/* Filter Bar */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.5 }}
              className="bg-white dark:bg-gray-900 rounded-2xl p-4 border border-gray-200 dark:border-gray-800 mb-6"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <button
                    onClick={() => setShowInactive(true)}
                    className={`px-4 py-2 rounded-lg font-semibold transition-colors ${
                      showInactive
                        ? 'bg-blue-600 text-white'
                        : 'bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700'
                    }`}
                  >
                    All ({allPositions.length})
                  </button>
                  <button
                    onClick={() => setShowInactive(false)}
                    className={`px-4 py-2 rounded-lg font-semibold transition-colors ${
                      !showInactive
                        ? 'bg-blue-600 text-white'
                        : 'bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700'
                    }`}
                  >
                    Active Only ({activePositions})
                  </button>
                </div>

                <Link
                  href="/pools"
                  className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white rounded-lg font-semibold transition-all"
                >
                  <Plus className="w-4 h-4" />
                  New Position
                </Link>
              </div>
            </motion.div>

            {/* Positions Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {filteredPositions.map((position, index) => (
                <motion.div
                  key={position.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.6 + index * 0.05 }}
                >
                  <PositionCard position={position} onViewDetails={handleViewDetails} />
                </motion.div>
              ))}
            </div>

            {/* Info Cards */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.8 }}
              className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-6"
            >
              <div className="bg-white dark:bg-gray-900 rounded-2xl p-6 border border-gray-200 dark:border-gray-800">
                <h3 className="font-bold text-lg mb-2">📊 Track Your Performance</h3>
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  Monitor your position value, APR, and unclaimed fees in real-time.
                </p>
              </div>
              <div className="bg-white dark:bg-gray-900 rounded-2xl p-6 border border-gray-200 dark:border-gray-800">
                <h3 className="font-bold text-lg mb-2">💰 Collect Fees Anytime</h3>
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  Your fees accumulate automatically. Collect them whenever you want.
                </p>
              </div>
              <div className="bg-white dark:bg-gray-900 rounded-2xl p-6 border border-gray-200 dark:border-gray-800">
                <h3 className="font-bold text-lg mb-2">🎨 NFT Positions</h3>
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  Each position is an NFT that you fully own and can transfer.
                </p>
              </div>
            </motion.div>
          </>
        )}
      </main>

      {/* Position Details Modal */}
      <PositionDetailsModal
        position={selectedPosition}
        open={isDetailsOpen}
        onOpenChange={setIsDetailsOpen}
      />
    </div>
  );
}
