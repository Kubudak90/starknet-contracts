'use client';

import { PoolPosition } from '@/lib/types/pool';
import { getPoolDisplayName, formatPoolFee } from '@/lib/constants/pools';
import { isInRange, calculatePositionAPR, getTotalUnclaimedFeesUSD } from '@/lib/constants/positions';
import { formatCurrency, formatTokenAmount } from '@/lib/utils/format';
import { TrendingUp, Droplets, DollarSign, Circle, ExternalLink } from 'lucide-react';
import { motion } from 'framer-motion';

interface PositionCardProps {
  position: PoolPosition;
  onViewDetails: (position: PoolPosition) => void;
}

export function PositionCard({ position, onViewDetails }: PositionCardProps) {
  const displayName = getPoolDisplayName(position.pool);
  const feeLabel = formatPoolFee(position.pool.fee);
  const inRange = isInRange(position);
  const apr = calculatePositionAPR(position);
  const totalFees = getTotalUnclaimedFeesUSD(position);

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      whileHover={{ y: -4 }}
      className="bg-white dark:bg-gray-900 rounded-2xl p-6 border border-gray-200 dark:border-gray-800 hover:border-blue-500 dark:hover:border-blue-500 transition-all cursor-pointer"
      onClick={() => onViewDetails(position)}
    >
      {/* Header */}
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-3">
          <div className="flex -space-x-2">
            <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center text-white font-bold border-2 border-white dark:border-gray-900">
              {position.pool.token0.symbol.substring(0, 2)}
            </div>
            <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-purple-600 rounded-full flex items-center justify-center text-white font-bold border-2 border-white dark:border-gray-900">
              {position.pool.token1.symbol.substring(0, 2)}
            </div>
          </div>
          <div>
            <h3 className="font-bold text-lg">{displayName}</h3>
            <div className="flex items-center gap-2 mt-1">
              <span className="text-xs text-gray-500 bg-gray-100 dark:bg-gray-800 px-2 py-0.5 rounded">
                {feeLabel}
              </span>
              <span className="text-xs text-gray-500">#{position.tokenId}</span>
            </div>
          </div>
        </div>

        {/* Status Badge */}
        <div className={`flex items-center gap-1 px-2 py-1 rounded-full text-xs font-semibold ${
          inRange
            ? 'bg-green-100 text-green-700 dark:bg-green-900/20 dark:text-green-400'
            : 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400'
        }`}>
          <Circle className={`w-2 h-2 fill-current ${inRange ? 'animate-pulse' : ''}`} />
          {inRange ? 'In Range' : 'Out of Range'}
        </div>
      </div>

      {/* Position Value */}
      <div className="mb-4 p-4 bg-gradient-to-br from-blue-50 to-purple-50 dark:from-blue-900/10 dark:to-purple-900/10 rounded-xl border border-blue-200 dark:border-blue-900/20">
        <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">Position Value</div>
        <div className="text-3xl font-bold">{formatCurrency(position.valueUSD)}</div>
      </div>

      {/* Liquidity Amounts */}
      <div className="grid grid-cols-2 gap-3 mb-4">
        <div className="bg-gray-50 dark:bg-gray-800/50 rounded-xl p-3">
          <div className="text-xs text-gray-500 mb-1">{position.pool.token0.symbol}</div>
          <div className="font-semibold">{formatTokenAmount(position.token0Amount, 4)}</div>
        </div>
        <div className="bg-gray-50 dark:bg-gray-800/50 rounded-xl p-3">
          <div className="text-xs text-gray-500 mb-1">{position.pool.token1.symbol}</div>
          <div className="font-semibold">{formatTokenAmount(position.token1Amount, 4)}</div>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 gap-4 pb-4 border-b border-gray-200 dark:border-gray-800">
        <div>
          <div className="flex items-center gap-1 text-xs text-gray-500 mb-1">
            <TrendingUp className="w-3 h-3" />
            APR
          </div>
          <div className="font-semibold text-green-600">{apr.toFixed(1)}%</div>
        </div>

        <div>
          <div className="flex items-center gap-1 text-xs text-gray-500 mb-1">
            <DollarSign className="w-3 h-3" />
            Unclaimed Fees
          </div>
          <div className="font-semibold text-green-600">{formatCurrency(totalFees)}</div>
        </div>
      </div>

      {/* Fee Details */}
      <div className="mt-4 space-y-2">
        <div className="flex items-center justify-between text-sm">
          <span className="text-gray-600 dark:text-gray-400">
            {position.pool.token0.symbol} fees
          </span>
          <span className="font-semibold">{position.unclaimedFees0}</span>
        </div>
        <div className="flex items-center justify-between text-sm">
          <span className="text-gray-600 dark:text-gray-400">
            {position.pool.token1.symbol} fees
          </span>
          <span className="font-semibold">{position.unclaimedFees1}</span>
        </div>
      </div>

      {/* View Details Button */}
      <button
        onClick={(e) => {
          e.stopPropagation();
          onViewDetails(position);
        }}
        className="w-full mt-4 py-3 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 rounded-xl font-semibold transition-all flex items-center justify-center gap-2"
      >
        Manage Position
        <ExternalLink className="w-4 h-4" />
      </button>
    </motion.div>
  );
}
