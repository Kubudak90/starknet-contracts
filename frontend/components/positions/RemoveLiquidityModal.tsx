'use client';

import { useState, useEffect } from 'react';
import * as Dialog from '@radix-ui/react-dialog';
import { X, Minus, Loader2, AlertTriangle } from 'lucide-react';
import { PoolPosition } from '@/lib/types/pool';
import { getPoolDisplayName } from '@/lib/constants/pools';
import { formatCurrency, formatTokenAmount } from '@/lib/utils/format';
import { motion } from 'framer-motion';

interface RemoveLiquidityModalProps {
  position: PoolPosition | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function RemoveLiquidityModal({ position, open, onOpenChange }: RemoveLiquidityModalProps) {
  const [percentage, setPercentage] = useState(100);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (!open) {
      setPercentage(100);
    }
  }, [open]);

  const handleRemoveLiquidity = async () => {
    if (!position) return;

    setIsLoading(true);
    try {
      // TODO: Implement actual remove liquidity logic
      await new Promise(resolve => setTimeout(resolve, 2000));
      console.log('Remove liquidity:', {
        position,
        percentage,
      });
      alert(`Successfully removed ${percentage}% of liquidity! (This is a demo)`);
      onOpenChange(false);
    } catch (error) {
      console.error('Remove liquidity failed:', error);
      alert('Remove liquidity failed! (This is a demo)');
    } finally {
      setIsLoading(false);
    }
  };

  if (!position) return null;

  const token0Amount = (parseFloat(position.token0Amount) * percentage / 100).toFixed(6);
  const token1Amount = (parseFloat(position.token1Amount) * percentage / 100).toFixed(6);
  const estimatedValue = position.valueUSD * percentage / 100;

  const presetPercentages = [25, 50, 75, 100];

  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/50 backdrop-blur-sm" />
        <Dialog.Content className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-lg bg-white dark:bg-gray-900 rounded-2xl shadow-xl p-6 max-h-[90vh] overflow-y-auto">
          {/* Header */}
          <div className="flex items-center justify-between mb-6">
            <Dialog.Title className="text-xl font-bold">
              Remove Liquidity
            </Dialog.Title>
            <Dialog.Close asChild>
              <button className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors">
                <X className="w-5 h-5" />
              </button>
            </Dialog.Close>
          </div>

          {/* Pool Info */}
          <div className="mb-6 p-4 bg-gray-50 dark:bg-gray-800/50 rounded-xl">
            <div className="flex items-center gap-3 mb-2">
              <div className="flex -space-x-2">
                <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center text-white text-xs font-bold border-2 border-white dark:border-gray-900">
                  {position.pool.token0.symbol.substring(0, 2)}
                </div>
                <div className="w-8 h-8 bg-gradient-to-br from-purple-500 to-purple-600 rounded-full flex items-center justify-center text-white text-xs font-bold border-2 border-white dark:border-gray-900">
                  {position.pool.token1.symbol.substring(0, 2)}
                </div>
              </div>
              <div>
                <h3 className="font-bold">{getPoolDisplayName(position.pool)}</h3>
                <span className="text-xs text-gray-500">Position #{position.tokenId}</span>
              </div>
            </div>
          </div>

          {/* Percentage Selector */}
          <div className="mb-6">
            <div className="flex items-center justify-between mb-3">
              <label className="font-semibold">Amount to Remove</label>
              <span className="text-2xl font-bold text-blue-600">{percentage}%</span>
            </div>

            {/* Slider */}
            <input
              type="range"
              min="1"
              max="100"
              value={percentage}
              onChange={(e) => setPercentage(Number(e.target.value))}
              className="w-full h-2 bg-gray-200 dark:bg-gray-700 rounded-lg appearance-none cursor-pointer accent-blue-600"
            />

            {/* Preset Buttons */}
            <div className="grid grid-cols-4 gap-2 mt-4">
              {presetPercentages.map((preset) => (
                <button
                  key={preset}
                  onClick={() => setPercentage(preset)}
                  className={`py-2 px-3 rounded-lg font-semibold transition-colors ${
                    percentage === preset
                      ? 'bg-blue-600 text-white'
                      : 'bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700'
                  }`}
                >
                  {preset}%
                </button>
              ))}
            </div>
          </div>

          {/* You Will Receive */}
          <div className="mb-6 p-4 bg-gradient-to-br from-blue-50 to-purple-50 dark:from-blue-900/10 dark:to-purple-900/10 rounded-xl border border-blue-200 dark:border-blue-900/20">
            <div className="text-sm text-gray-600 dark:text-gray-400 mb-3">You will receive</div>

            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-6 h-6 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center text-white text-xs font-bold">
                    {position.pool.token0.symbol.substring(0, 1)}
                  </div>
                  <span className="font-semibold">{position.pool.token0.symbol}</span>
                </div>
                <span className="text-lg font-bold">{formatTokenAmount(token0Amount, 6)}</span>
              </div>

              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-6 h-6 bg-gradient-to-br from-purple-500 to-purple-600 rounded-full flex items-center justify-center text-white text-xs font-bold">
                    {position.pool.token1.symbol.substring(0, 1)}
                  </div>
                  <span className="font-semibold">{position.pool.token1.symbol}</span>
                </div>
                <span className="text-lg font-bold">{formatTokenAmount(token1Amount, 6)}</span>
              </div>

              <div className="pt-3 border-t border-blue-200 dark:border-blue-900/20">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-600 dark:text-gray-400">Estimated Value</span>
                  <span className="font-bold">{formatCurrency(estimatedValue)}</span>
                </div>
              </div>
            </div>
          </div>

          {/* Unclaimed Fees Info */}
          {(parseFloat(position.unclaimedFees0) > 0 || parseFloat(position.unclaimedFees1) > 0) && (
            <div className="mb-6 p-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-xl">
              <div className="flex gap-2">
                <AlertTriangle className="w-5 h-5 text-yellow-600 flex-shrink-0" />
                <div className="text-sm text-yellow-800 dark:text-yellow-300">
                  <p className="font-semibold mb-1">Unclaimed Fees</p>
                  <p className="mb-2">
                    You have unclaimed fees. Make sure to collect them before removing liquidity.
                  </p>
                  <div className="space-y-1 text-xs">
                    <div>{position.pool.token0.symbol}: {position.unclaimedFees0}</div>
                    <div>{position.pool.token1.symbol}: {position.unclaimedFees1}</div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Buttons */}
          <div className="flex gap-3">
            <button
              onClick={() => onOpenChange(false)}
              className="flex-1 py-3 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 rounded-xl font-semibold transition-all"
            >
              Cancel
            </button>
            <button
              onClick={handleRemoveLiquidity}
              disabled={isLoading || percentage === 0}
              className="flex-1 py-3 bg-gradient-to-r from-red-600 to-pink-600 hover:from-red-700 hover:to-pink-700 text-white rounded-xl font-bold transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              {isLoading ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  Removing...
                </>
              ) : (
                <>
                  <Minus className="w-5 h-5" />
                  Remove Liquidity
                </>
              )}
            </button>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
