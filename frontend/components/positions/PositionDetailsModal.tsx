'use client';

import { useState } from 'react';
import * as Dialog from '@radix-ui/react-dialog';
import { X, DollarSign, TrendingUp, Droplets, Circle, Wallet, Minus } from 'lucide-react';
import { PoolPosition } from '@/lib/types/pool';
import { getPoolDisplayName, formatPoolFee } from '@/lib/constants/pools';
import { isInRange, calculatePositionAPR, getTotalUnclaimedFeesUSD } from '@/lib/constants/positions';
import { formatCurrency, formatTokenAmount } from '@/lib/utils/format';
import { RemoveLiquidityModal } from './RemoveLiquidityModal';
import { motion } from 'framer-motion';

interface PositionDetailsModalProps {
  position: PoolPosition | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function PositionDetailsModal({ position, open, onOpenChange }: PositionDetailsModalProps) {
  const [isCollectingFees, setIsCollectingFees] = useState(false);
  const [isRemoveModalOpen, setIsRemoveModalOpen] = useState(false);

  if (!position) return null;

  const displayName = getPoolDisplayName(position.pool);
  const feeLabel = formatPoolFee(position.pool.fee);
  const inRange = isInRange(position);
  const apr = calculatePositionAPR(position);
  const totalFees = getTotalUnclaimedFeesUSD(position);

  const handleCollectFees = async () => {
    setIsCollectingFees(true);
    try {
      // TODO: Implement actual collect fees logic
      await new Promise(resolve => setTimeout(resolve, 2000));
      console.log('Collect fees:', position);
      alert('Fees collected successfully! (This is a demo)');
    } catch (error) {
      console.error('Collect fees failed:', error);
      alert('Collect fees failed! (This is a demo)');
    } finally {
      setIsCollectingFees(false);
    }
  };

  const handleRemoveLiquidity = () => {
    onOpenChange(false);
    setIsRemoveModalOpen(true);
  };

  // Calculate price range (mock)
  const minPrice = '1800';
  const maxPrice = '2200';
  const currentPrice = '2000';

  return (
    <>
      <Dialog.Root open={open} onOpenChange={onOpenChange}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/50 backdrop-blur-sm" />
          <Dialog.Content className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-2xl bg-white dark:bg-gray-900 rounded-2xl shadow-xl p-6 max-h-[90vh] overflow-y-auto">
            {/* Header */}
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className="flex -space-x-2">
                  <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center text-white font-bold border-2 border-white dark:border-gray-900">
                    {position.pool.token0.symbol.substring(0, 2)}
                  </div>
                  <div className="w-12 h-12 bg-gradient-to-br from-purple-500 to-purple-600 rounded-full flex items-center justify-center text-white font-bold border-2 border-white dark:border-gray-900">
                    {position.pool.token1.symbol.substring(0, 2)}
                  </div>
                </div>
                <div>
                  <Dialog.Title className="text-xl font-bold">{displayName}</Dialog.Title>
                  <div className="flex items-center gap-2 mt-1">
                    <span className="text-sm text-gray-500 bg-gray-100 dark:bg-gray-800 px-2 py-0.5 rounded">
                      {feeLabel}
                    </span>
                    <span className="text-sm text-gray-500">NFT #{position.tokenId}</span>
                  </div>
                </div>
              </div>
              <Dialog.Close asChild>
                <button className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors">
                  <X className="w-5 h-5" />
                </button>
              </Dialog.Close>
            </div>

            {/* Status and Value */}
            <div className="grid grid-cols-2 gap-4 mb-6">
              <div className="p-4 bg-gradient-to-br from-blue-50 to-purple-50 dark:from-blue-900/10 dark:to-purple-900/10 rounded-xl border border-blue-200 dark:border-blue-900/20">
                <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Position Value</div>
                <div className="text-3xl font-bold">{formatCurrency(position.valueUSD)}</div>
              </div>

              <div className={`p-4 rounded-xl border ${
                inRange
                  ? 'bg-green-50 dark:bg-green-900/10 border-green-200 dark:border-green-900/20'
                  : 'bg-gray-50 dark:bg-gray-800/50 border-gray-200 dark:border-gray-800'
              }`}>
                <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Status</div>
                <div className="flex items-center gap-2">
                  <Circle className={`w-3 h-3 fill-current ${
                    inRange ? 'text-green-600 animate-pulse' : 'text-gray-400'
                  }`} />
                  <span className="text-xl font-bold">
                    {inRange ? 'In Range' : 'Out of Range'}
                  </span>
                </div>
              </div>
            </div>

            {/* Stats Grid */}
            <div className="grid grid-cols-3 gap-4 mb-6">
              <div className="p-4 bg-gray-50 dark:bg-gray-800/50 rounded-xl">
                <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400 mb-2">
                  <TrendingUp className="w-4 h-4" />
                  APR
                </div>
                <div className="text-xl font-bold text-green-600">{apr.toFixed(1)}%</div>
              </div>

              <div className="p-4 bg-gray-50 dark:bg-gray-800/50 rounded-xl">
                <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400 mb-2">
                  <Droplets className="w-4 h-4" />
                  Liquidity
                </div>
                <div className="text-xl font-bold">{formatCurrency(position.valueUSD)}</div>
              </div>

              <div className="p-4 bg-gray-50 dark:bg-gray-800/50 rounded-xl">
                <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400 mb-2">
                  <DollarSign className="w-4 h-4" />
                  Pool TVL
                </div>
                <div className="text-xl font-bold">{formatCurrency(position.pool.tvl)}</div>
              </div>
            </div>

            {/* Liquidity Amounts */}
            <div className="mb-6">
              <h3 className="font-semibold mb-3">Liquidity</h3>
              <div className="grid grid-cols-2 gap-4">
                <div className="p-4 bg-gray-50 dark:bg-gray-800/50 rounded-xl">
                  <div className="flex items-center gap-2 mb-2">
                    <div className="w-6 h-6 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center text-white text-xs font-bold">
                      {position.pool.token0.symbol.substring(0, 1)}
                    </div>
                    <span className="text-sm text-gray-600 dark:text-gray-400">
                      {position.pool.token0.symbol}
                    </span>
                  </div>
                  <div className="text-2xl font-bold">{formatTokenAmount(position.token0Amount, 6)}</div>
                </div>

                <div className="p-4 bg-gray-50 dark:bg-gray-800/50 rounded-xl">
                  <div className="flex items-center gap-2 mb-2">
                    <div className="w-6 h-6 bg-gradient-to-br from-purple-500 to-purple-600 rounded-full flex items-center justify-center text-white text-xs font-bold">
                      {position.pool.token1.symbol.substring(0, 1)}
                    </div>
                    <span className="text-sm text-gray-600 dark:text-gray-400">
                      {position.pool.token1.symbol}
                    </span>
                  </div>
                  <div className="text-2xl font-bold">{formatTokenAmount(position.token1Amount, 6)}</div>
                </div>
              </div>
            </div>

            {/* Price Range */}
            <div className="mb-6 p-4 border border-gray-200 dark:border-gray-800 rounded-xl">
              <h3 className="font-semibold mb-3">Selected Range</h3>
              <div className="grid grid-cols-3 gap-4 text-center">
                <div>
                  <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Min Price</div>
                  <div className="font-bold">{minPrice}</div>
                  <div className="text-xs text-gray-500 mt-1">
                    {position.pool.token1.symbol} per {position.pool.token0.symbol}
                  </div>
                </div>
                <div>
                  <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Current</div>
                  <div className="font-bold text-blue-600">{currentPrice}</div>
                  <div className="text-xs text-gray-500 mt-1">
                    {position.pool.token1.symbol} per {position.pool.token0.symbol}
                  </div>
                </div>
                <div>
                  <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Max Price</div>
                  <div className="font-bold">{maxPrice}</div>
                  <div className="text-xs text-gray-500 mt-1">
                    {position.pool.token1.symbol} per {position.pool.token0.symbol}
                  </div>
                </div>
              </div>
            </div>

            {/* Unclaimed Fees */}
            <div className="mb-6 p-4 bg-gradient-to-br from-green-50 to-emerald-50 dark:from-green-900/10 dark:to-emerald-900/10 rounded-xl border border-green-200 dark:border-green-900/20">
              <div className="flex items-center justify-between mb-3">
                <h3 className="font-semibold">Unclaimed Fees</h3>
                <div className="text-xl font-bold text-green-600">{formatCurrency(totalFees)}</div>
              </div>
              <div className="space-y-2 mb-4">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-600 dark:text-gray-400">
                    {position.pool.token0.symbol}
                  </span>
                  <span className="font-semibold">{position.unclaimedFees0}</span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-600 dark:text-gray-400">
                    {position.pool.token1.symbol}
                  </span>
                  <span className="font-semibold">{position.unclaimedFees1}</span>
                </div>
              </div>
              <button
                onClick={handleCollectFees}
                disabled={isCollectingFees || totalFees === 0}
                className="w-full py-3 bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white rounded-xl font-bold transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                {isCollectingFees ? (
                  <>
                    <motion.div
                      animate={{ rotate: 360 }}
                      transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
                    >
                      <Wallet className="w-5 h-5" />
                    </motion.div>
                    Collecting...
                  </>
                ) : (
                  <>
                    <Wallet className="w-5 h-5" />
                    Collect Fees
                  </>
                )}
              </button>
            </div>

            {/* Remove Liquidity Button */}
            <button
              onClick={handleRemoveLiquidity}
              className="w-full py-3 bg-gradient-to-r from-red-600 to-pink-600 hover:from-red-700 hover:to-pink-700 text-white rounded-xl font-bold transition-all flex items-center justify-center gap-2"
            >
              <Minus className="w-5 h-5" />
              Remove Liquidity
            </button>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>

      {/* Remove Liquidity Modal */}
      <RemoveLiquidityModal
        position={position}
        open={isRemoveModalOpen}
        onOpenChange={setIsRemoveModalOpen}
      />
    </>
  );
}
