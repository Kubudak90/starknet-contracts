'use client';

import { useState, useMemo } from 'react';
import { Header } from '@/components/Header';
import { PoolCard } from '@/components/pools/PoolCard';
import { PoolStats } from '@/components/pools/PoolStats';
import { AddLiquidityModal } from '@/components/pools/AddLiquidityModal';
import { Pool } from '@/lib/types/pool';
import { getPoolsByChainId } from '@/lib/constants/pools';
import { Search, SlidersHorizontal, TrendingDown, TrendingUp } from 'lucide-react';
import { useChainId } from 'wagmi';
import { motion } from 'framer-motion';

type SortBy = 'tvl' | 'volume' | 'apr' | 'fees';
type SortOrder = 'asc' | 'desc';

export default function PoolsPage() {
  const chainId = useChainId();
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState<SortBy>('tvl');
  const [sortOrder, setSortOrder] = useState<SortOrder>('desc');
  const [selectedPool, setSelectedPool] = useState<Pool | null>(null);
  const [isAddLiquidityOpen, setIsAddLiquidityOpen] = useState(false);

  const pools = getPoolsByChainId(chainId);

  // Filter and sort pools
  const filteredAndSortedPools = useMemo(() => {
    let filtered = pools.filter((pool) => {
      const query = searchQuery.toLowerCase();
      return (
        pool.token0.symbol.toLowerCase().includes(query) ||
        pool.token1.symbol.toLowerCase().includes(query) ||
        pool.token0.name.toLowerCase().includes(query) ||
        pool.token1.name.toLowerCase().includes(query)
      );
    });

    // Sort
    filtered.sort((a, b) => {
      let aValue: number;
      let bValue: number;

      switch (sortBy) {
        case 'tvl':
          aValue = a.tvl;
          bValue = b.tvl;
          break;
        case 'volume':
          aValue = a.volume24h;
          bValue = b.volume24h;
          break;
        case 'apr':
          aValue = a.apr;
          bValue = b.apr;
          break;
        case 'fees':
          aValue = a.fees24h;
          bValue = b.fees24h;
          break;
        default:
          aValue = a.tvl;
          bValue = b.tvl;
      }

      return sortOrder === 'desc' ? bValue - aValue : aValue - bValue;
    });

    return filtered;
  }, [pools, searchQuery, sortBy, sortOrder]);

  const handleAddLiquidity = (pool: Pool) => {
    setSelectedPool(pool);
    setIsAddLiquidityOpen(true);
  };

  const toggleSort = (newSortBy: SortBy) => {
    if (sortBy === newSortBy) {
      setSortOrder(sortOrder === 'desc' ? 'asc' : 'desc');
    } else {
      setSortBy(newSortBy);
      setSortOrder('desc');
    }
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
          <h1 className="text-4xl font-bold mb-2">Liquidity Pools</h1>
          <p className="text-gray-600 dark:text-gray-400">
            Provide liquidity to earn trading fees and rewards
          </p>
        </motion.div>

        {/* Pool Statistics */}
        <PoolStats pools={pools} />

        {/* Search and Filter Bar */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-white dark:bg-gray-900 rounded-2xl p-4 border border-gray-200 dark:border-gray-800 mb-6"
        >
          <div className="flex flex-col md:flex-row gap-4">
            {/* Search */}
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                placeholder="Search pools by token..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-3 bg-gray-100 dark:bg-gray-800 rounded-xl outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* Sort Options */}
            <div className="flex gap-2 flex-wrap">
              <button
                onClick={() => toggleSort('tvl')}
                className={`px-4 py-2 rounded-lg font-semibold transition-colors flex items-center gap-2 ${
                  sortBy === 'tvl'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700'
                }`}
              >
                TVL
                {sortBy === 'tvl' && (
                  sortOrder === 'desc' ? <TrendingDown className="w-4 h-4" /> : <TrendingUp className="w-4 h-4" />
                )}
              </button>
              <button
                onClick={() => toggleSort('volume')}
                className={`px-4 py-2 rounded-lg font-semibold transition-colors flex items-center gap-2 ${
                  sortBy === 'volume'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700'
                }`}
              >
                Volume
                {sortBy === 'volume' && (
                  sortOrder === 'desc' ? <TrendingDown className="w-4 h-4" /> : <TrendingUp className="w-4 h-4" />
                )}
              </button>
              <button
                onClick={() => toggleSort('apr')}
                className={`px-4 py-2 rounded-lg font-semibold transition-colors flex items-center gap-2 ${
                  sortBy === 'apr'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700'
                }`}
              >
                APR
                {sortBy === 'apr' && (
                  sortOrder === 'desc' ? <TrendingDown className="w-4 h-4" /> : <TrendingUp className="w-4 h-4" />
                )}
              </button>
              <button
                onClick={() => toggleSort('fees')}
                className={`px-4 py-2 rounded-lg font-semibold transition-colors flex items-center gap-2 ${
                  sortBy === 'fees'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700'
                }`}
              >
                Fees
                {sortBy === 'fees' && (
                  sortOrder === 'desc' ? <TrendingDown className="w-4 h-4" /> : <TrendingUp className="w-4 h-4" />
                )}
              </button>
            </div>
          </div>
        </motion.div>

        {/* Pool Grid */}
        {filteredAndSortedPools.length === 0 ? (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="text-center py-16"
          >
            <div className="text-6xl mb-4">🏊</div>
            <h3 className="text-xl font-semibold mb-2">No pools found</h3>
            <p className="text-gray-600 dark:text-gray-400">
              Try adjusting your search or switch to a different network
            </p>
          </motion.div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredAndSortedPools.map((pool, index) => (
              <motion.div
                key={pool.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.05 }}
              >
                <PoolCard pool={pool} onAddLiquidity={handleAddLiquidity} />
              </motion.div>
            ))}
          </div>
        )}

        {/* Info Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-6"
        >
          <div className="bg-white dark:bg-gray-900 rounded-2xl p-6 border border-gray-200 dark:border-gray-800">
            <h3 className="font-bold text-lg mb-2">💧 Concentrated Liquidity</h3>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Provide liquidity in specific price ranges for higher capital efficiency and better returns.
            </p>
          </div>
          <div className="bg-white dark:bg-gray-900 rounded-2xl p-6 border border-gray-200 dark:border-gray-800">
            <h3 className="font-bold text-lg mb-2">⚡ Multiple Fee Tiers</h3>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Choose from 0.01%, 0.05%, 0.3%, or 1% fee tiers based on the volatility of your pair.
            </p>
          </div>
          <div className="bg-white dark:bg-gray-900 rounded-2xl p-6 border border-gray-200 dark:border-gray-800">
            <h3 className="font-bold text-lg mb-2">🎯 NFT Positions</h3>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Each liquidity position is represented as an NFT, making them transferable and composable.
            </p>
          </div>
        </motion.div>
      </main>

      {/* Add Liquidity Modal */}
      <AddLiquidityModal
        pool={selectedPool}
        open={isAddLiquidityOpen}
        onOpenChange={setIsAddLiquidityOpen}
      />
    </div>
  );
}
