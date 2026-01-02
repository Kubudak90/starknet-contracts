'use client';

import { Pool } from '@/lib/types/pool';
import { formatCurrency } from '@/lib/utils/format';
import { TrendingUp, Droplets, DollarSign, Activity } from 'lucide-react';
import { motion } from 'framer-motion';

interface PoolStatsProps {
  pools: Pool[];
}

export function PoolStats({ pools }: PoolStatsProps) {
  const totalTVL = pools.reduce((sum, pool) => sum + pool.tvl, 0);
  const totalVolume24h = pools.reduce((sum, pool) => sum + pool.volume24h, 0);
  const totalFees24h = pools.reduce((sum, pool) => sum + pool.fees24h, 0);
  const avgAPR = pools.length > 0
    ? pools.reduce((sum, pool) => sum + pool.apr, 0) / pools.length
    : 0;

  const stats = [
    {
      label: 'Total TVL',
      value: formatCurrency(totalTVL),
      icon: Droplets,
      color: 'text-blue-600',
      bgColor: 'bg-blue-100 dark:bg-blue-900/20',
    },
    {
      label: '24h Volume',
      value: formatCurrency(totalVolume24h),
      icon: Activity,
      color: 'text-purple-600',
      bgColor: 'bg-purple-100 dark:bg-purple-900/20',
    },
    {
      label: '24h Fees',
      value: formatCurrency(totalFees24h),
      icon: DollarSign,
      color: 'text-green-600',
      bgColor: 'bg-green-100 dark:bg-green-900/20',
    },
    {
      label: 'Avg APR',
      value: `${avgAPR.toFixed(1)}%`,
      icon: TrendingUp,
      color: 'text-orange-600',
      bgColor: 'bg-orange-100 dark:bg-orange-900/20',
    },
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
      {stats.map((stat, index) => (
        <motion.div
          key={stat.label}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: index * 0.1 }}
          className="bg-white dark:bg-gray-900 rounded-2xl p-6 border border-gray-200 dark:border-gray-800"
        >
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm text-gray-600 dark:text-gray-400">{stat.label}</span>
            <div className={`p-2 ${stat.bgColor} rounded-lg`}>
              <stat.icon className={`w-5 h-5 ${stat.color}`} />
            </div>
          </div>
          <div className="text-2xl font-bold">{stat.value}</div>
        </motion.div>
      ))}
    </div>
  );
}
