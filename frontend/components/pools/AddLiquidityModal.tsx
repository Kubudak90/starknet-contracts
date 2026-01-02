'use client';

import { useState, useEffect } from 'react';
import * as Dialog from '@radix-ui/react-dialog';
import * as Tabs from '@radix-ui/react-tabs';
import { X, Plus, Minus, Info, Settings, Loader2 } from 'lucide-react';
import { Pool } from '@/lib/types/pool';
import { getPoolDisplayName } from '@/lib/constants/pools';
import { useAccount, useBalance } from 'wagmi';
import { motion } from 'framer-motion';

interface AddLiquidityModalProps {
  pool: Pool | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function AddLiquidityModal({ pool, open, onOpenChange }: AddLiquidityModalProps) {
  const { address } = useAccount();
  const [amount0, setAmount0] = useState('');
  const [amount1, setAmount1] = useState('');
  const [minPrice, setMinPrice] = useState('');
  const [maxPrice, setMaxPrice] = useState('');
  const [isFullRange, setIsFullRange] = useState(true);
  const [slippage, setSlippage] = useState(0.5);
  const [isLoading, setIsLoading] = useState(false);

  const { data: balance0 } = useBalance({
    address,
    token: pool?.token0.address === '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'
      ? undefined
      : pool?.token0.address as `0x${string}`,
  });

  const { data: balance1 } = useBalance({
    address,
    token: pool?.token1.address === '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'
      ? undefined
      : pool?.token1.address as `0x${string}`,
  });

  useEffect(() => {
    if (!open) {
      // Reset form when modal closes
      setAmount0('');
      setAmount1('');
      setMinPrice('');
      setMaxPrice('');
      setIsFullRange(true);
    }
  }, [open]);

  // Auto-calculate amount1 based on amount0 (simplified)
  useEffect(() => {
    if (amount0 && pool) {
      // Mock price: 1 ETH = 2000 USDC
      const mockRate = pool.token0.symbol === 'ETH' && pool.token1.symbol === 'USDC' ? 2000 : 1;
      setAmount1((parseFloat(amount0) * mockRate).toFixed(6));
    }
  }, [amount0, pool]);

  const handleAddLiquidity = async () => {
    if (!pool) return;

    setIsLoading(true);
    try {
      // TODO: Implement actual add liquidity logic
      await new Promise(resolve => setTimeout(resolve, 2000));
      console.log('Add liquidity:', {
        pool,
        amount0,
        amount1,
        minPrice,
        maxPrice,
        isFullRange,
        slippage,
      });
      alert('Liquidity added successfully! (This is a demo)');
      onOpenChange(false);
    } catch (error) {
      console.error('Add liquidity failed:', error);
      alert('Add liquidity failed! (This is a demo)');
    } finally {
      setIsLoading(false);
    }
  };

  if (!pool) return null;

  const canAdd = amount0 && amount1 && parseFloat(amount0) > 0 && parseFloat(amount1) > 0;

  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/50 backdrop-blur-sm" />
        <Dialog.Content className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-lg bg-white dark:bg-gray-900 rounded-2xl shadow-xl p-6 max-h-[90vh] overflow-y-auto">
          {/* Header */}
          <div className="flex items-center justify-between mb-6">
            <Dialog.Title className="text-xl font-bold">
              Add Liquidity to {getPoolDisplayName(pool)}
            </Dialog.Title>
            <Dialog.Close asChild>
              <button className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors">
                <X className="w-5 h-5" />
              </button>
            </Dialog.Close>
          </div>

          <Tabs.Root defaultValue="standard" className="w-full">
            <Tabs.List className="flex gap-2 mb-6 bg-gray-100 dark:bg-gray-800 p-1 rounded-xl">
              <Tabs.Trigger
                value="standard"
                className="flex-1 py-2 px-4 rounded-lg font-semibold transition-colors data-[state=active]:bg-white data-[state=active]:dark:bg-gray-900 data-[state=active]:shadow"
              >
                Standard
              </Tabs.Trigger>
              <Tabs.Trigger
                value="concentrated"
                className="flex-1 py-2 px-4 rounded-lg font-semibold transition-colors data-[state=active]:bg-white data-[state=active]:dark:bg-gray-900 data-[state=active]:shadow"
              >
                Concentrated
              </Tabs.Trigger>
            </Tabs.List>

            <Tabs.Content value="standard" className="space-y-4">
              {/* Token 0 Input */}
              <div className="bg-gray-50 dark:bg-gray-800/50 rounded-2xl p-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm text-gray-600 dark:text-gray-400">
                    {pool.token0.symbol}
                  </span>
                  {balance0 && (
                    <span className="text-sm text-gray-600 dark:text-gray-400">
                      Balance: {parseFloat(balance0.formatted).toFixed(4)}
                    </span>
                  )}
                </div>
                <input
                  type="text"
                  value={amount0}
                  onChange={(e) => {
                    const value = e.target.value;
                    if (value === '' || /^\d*\.?\d*$/.test(value)) {
                      setAmount0(value);
                    }
                  }}
                  placeholder="0.0"
                  className="w-full text-3xl font-semibold bg-transparent outline-none"
                />
              </div>

              <div className="flex justify-center">
                <Plus className="w-5 h-5 text-gray-400" />
              </div>

              {/* Token 1 Input */}
              <div className="bg-gray-50 dark:bg-gray-800/50 rounded-2xl p-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm text-gray-600 dark:text-gray-400">
                    {pool.token1.symbol}
                  </span>
                  {balance1 && (
                    <span className="text-sm text-gray-600 dark:text-gray-400">
                      Balance: {parseFloat(balance1.formatted).toFixed(4)}
                    </span>
                  )}
                </div>
                <input
                  type="text"
                  value={amount1}
                  readOnly
                  placeholder="0.0"
                  className="w-full text-3xl font-semibold bg-transparent outline-none"
                />
              </div>

              {/* Info Box */}
              <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-xl p-4">
                <div className="flex gap-2">
                  <Info className="w-5 h-5 text-blue-600 flex-shrink-0" />
                  <div className="text-sm text-blue-800 dark:text-blue-300">
                    <p className="font-semibold mb-1">Full Range Position</p>
                    <p>
                      Your liquidity will be active across all price ranges, earning fees on all trades.
                    </p>
                  </div>
                </div>
              </div>
            </Tabs.Content>

            <Tabs.Content value="concentrated" className="space-y-4">
              {/* Token inputs (same as standard) */}
              <div className="bg-gray-50 dark:bg-gray-800/50 rounded-2xl p-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm text-gray-600 dark:text-gray-400">
                    {pool.token0.symbol}
                  </span>
                  {balance0 && (
                    <span className="text-sm text-gray-600 dark:text-gray-400">
                      Balance: {parseFloat(balance0.formatted).toFixed(4)}
                    </span>
                  )}
                </div>
                <input
                  type="text"
                  value={amount0}
                  onChange={(e) => {
                    const value = e.target.value;
                    if (value === '' || /^\d*\.?\d*$/.test(value)) {
                      setAmount0(value);
                    }
                  }}
                  placeholder="0.0"
                  className="w-full text-3xl font-semibold bg-transparent outline-none"
                />
              </div>

              <div className="flex justify-center">
                <Plus className="w-5 h-5 text-gray-400" />
              </div>

              <div className="bg-gray-50 dark:bg-gray-800/50 rounded-2xl p-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm text-gray-600 dark:text-gray-400">
                    {pool.token1.symbol}
                  </span>
                  {balance1 && (
                    <span className="text-sm text-gray-600 dark:text-gray-400">
                      Balance: {parseFloat(balance1.formatted).toFixed(4)}
                    </span>
                  )}
                </div>
                <input
                  type="text"
                  value={amount1}
                  readOnly
                  placeholder="0.0"
                  className="w-full text-3xl font-semibold bg-transparent outline-none"
                />
              </div>

              {/* Price Range */}
              <div className="border border-gray-200 dark:border-gray-800 rounded-xl p-4">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="font-semibold">Set Price Range</h3>
                  <button
                    onClick={() => setIsFullRange(!isFullRange)}
                    className={`text-sm font-semibold ${
                      isFullRange ? 'text-blue-600' : 'text-gray-500'
                    }`}
                  >
                    Full Range
                  </button>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-sm text-gray-600 dark:text-gray-400 mb-2 block">
                      Min Price
                    </label>
                    <input
                      type="text"
                      value={minPrice}
                      onChange={(e) => setMinPrice(e.target.value)}
                      placeholder="0.0"
                      disabled={isFullRange}
                      className="w-full py-3 px-4 bg-gray-100 dark:bg-gray-800 rounded-xl outline-none disabled:opacity-50"
                    />
                  </div>
                  <div>
                    <label className="text-sm text-gray-600 dark:text-gray-400 mb-2 block">
                      Max Price
                    </label>
                    <input
                      type="text"
                      value={maxPrice}
                      onChange={(e) => setMaxPrice(e.target.value)}
                      placeholder="∞"
                      disabled={isFullRange}
                      className="w-full py-3 px-4 bg-gray-100 dark:bg-gray-800 rounded-xl outline-none disabled:opacity-50"
                    />
                  </div>
                </div>

                <div className="mt-4 p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
                  <p className="text-xs text-yellow-800 dark:text-yellow-300">
                    Concentrated positions require active management. Your position will only earn fees
                    when the price is within your specified range.
                  </p>
                </div>
              </div>
            </Tabs.Content>
          </Tabs.Root>

          {/* Summary */}
          {canAdd && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="mt-4 p-4 bg-gray-50 dark:bg-gray-800/50 rounded-xl space-y-2"
            >
              <div className="flex items-center justify-between text-sm">
                <span className="text-gray-600 dark:text-gray-400">Estimated Share</span>
                <span className="font-semibold">0.05%</span>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-gray-600 dark:text-gray-400">Slippage Tolerance</span>
                <span className="font-semibold">{slippage}%</span>
              </div>
            </motion.div>
          )}

          {/* Add Button */}
          <button
            onClick={handleAddLiquidity}
            disabled={!canAdd || isLoading}
            className="w-full mt-6 py-4 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white rounded-xl font-bold transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
          >
            {isLoading ? (
              <>
                <Loader2 className="w-5 h-5 animate-spin" />
                Adding Liquidity...
              </>
            ) : (
              'Add Liquidity'
            )}
          </button>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
