'use client';

import { Pool } from '@/lib/types/pool';
import { formatPoolFee, getPoolDisplayName } from '@/lib/constants/pools';
import { formatNumber, formatCurrency } from '@/lib/utils/format';
import { TrendingUp, Droplets, DollarSign } from 'lucide-react';
import { motion } from 'framer-motion';

interface PoolCardProps {
  pool: Pool;
  onAddLiquidity: (pool: Pool) => void;
}

export function PoolCard({ pool, onAddLiquidity }: PoolCardProps) {
  const displayName = getPoolDisplayName(pool);
  const feeLabel = formatPoolFee(pool.fee);

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      whileHover={{ y: -4 }}
      className="bg-white dark:bg-gray-900 rounded-2xl p-6 border border-gray-200 dark:border-gray-800 hover:border-blue-500 dark:hover:border-blue-500 transition-all cursor-pointer"
      onClick={() => onAddLiquidity(pool)}
    >
      {/* Header */}
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-3">
          <div className="flex -space-x-2">
            <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center text-white font-bold border-2 border-white dark:border-gray-900">
              {pool.token0.symbol.substring(0, 2)}
            </div>
            <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-purple-600 rounded-full flex items-center justify-center text-white font-bold border-2 border-white dark:border-gray-900">
              {pool.token1.symbol.substring(0, 2)}
            </div>
          </div>
          <div>
            <h3 className="font-bold text-lg">{displayName}</h3>
            <span className="text-sm text-gray-500 bg-gray-100 dark:bg-gray-800 px-2 py-0.5 rounded">
              {feeLabel}
            </span>
          </div>
        </div>

        <div className="text-right">
          <div className="text-sm text-gray-500">APR</div>
          <div className="text-xl font-bold text-green-600 flex items-center gap-1">
            <TrendingUp className="w-4 h-4" />
            {pool.apr.toFixed(1)}%
          </div>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-3 gap-4">
        <div>
          <div className="flex items-center gap-1 text-xs text-gray-500 mb-1">
            <Droplets className="w-3 h-3" />
            TVL
          </div>
          <div className="font-semibold">{formatCurrency(pool.tvl)}</div>
        </div>

        <div>
          <div className="flex items-center gap-1 text-xs text-gray-500 mb-1">
            <DollarSign className="w-3 h-3" />
            Volume (24h)
          </div>
          <div className="font-semibold">{formatCurrency(pool.volume24h)}</div>
        </div>

        <div>
          <div className="flex items-center gap-1 text-xs text-gray-500 mb-1">
            <DollarSign className="w-3 h-3" />
            Fees (24h)
          </div>
          <div className="font-semibold text-green-600">{formatCurrency(pool.fees24h)}</div>
        </div>
      </div>

      {/* Volume 7d */}
      <div className="mt-4 pt-4 border-t border-gray-200 dark:border-gray-800">
        <div className="flex items-center justify-between text-sm">
          <span className="text-gray-500">7d Volume</span>
          <span className="font-semibold">{formatCurrency(pool.volume7d)}</span>
        </div>
      </div>

      {/* Add Liquidity Button */}
      <button
        onClick={(e) => {
          e.stopPropagation();
          onAddLiquidity(pool);
        }}
        className="w-full mt-4 py-3 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white rounded-xl font-semibold transition-all"
      >
        Add Liquidity
      </button>
    </motion.div>
  );
}
