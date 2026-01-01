'use client';

import { useState, useEffect } from 'react';
import { Header } from '@/components/Header';
import { SwapInput } from '@/components/swap/SwapInput';
import { SlippageSettings } from '@/components/swap/SlippageSettings';
import { Token } from '@/lib/types/token';
import { getTokensByChainId } from '@/lib/constants/tokens';
import { ArrowDown, ArrowDownUp, Loader2, AlertCircle } from 'lucide-react';
import { useAccount, useChainId } from 'wagmi';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { motion } from 'framer-motion';

export default function SwapPage() {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();

  const [tokenIn, setTokenIn] = useState<Token | null>(null);
  const [tokenOut, setTokenOut] = useState<Token | null>(null);
  const [amountIn, setAmountIn] = useState('');
  const [amountOut, setAmountOut] = useState('');
  const [slippage, setSlippage] = useState(0.5);
  const [isLoading, setIsLoading] = useState(false);
  const [priceImpact, setPriceImpact] = useState<number | null>(null);

  // Initialize default tokens when chain changes
  useEffect(() => {
    const tokens = getTokensByChainId(chainId);
    if (tokens.length > 0) {
      setTokenIn(tokens[0]); // ETH
      if (tokens.length > 1) {
        setTokenOut(tokens[1]); // USDC
      }
    }
  }, [chainId]);

  // Simulate price calculation (replace with actual quote logic)
  useEffect(() => {
    if (amountIn && tokenIn && tokenOut) {
      setIsLoading(true);
      const timer = setTimeout(() => {
        // Mock conversion: 1 ETH = 2000 USDC
        const mockRate = tokenIn.symbol === 'ETH' && tokenOut.symbol === 'USDC' ? 2000 : 0.0005;
        const output = (parseFloat(amountIn) * mockRate).toFixed(6);
        setAmountOut(output);
        setPriceImpact(0.05); // Mock 0.05% price impact
        setIsLoading(false);
      }, 500);
      return () => clearTimeout(timer);
    } else {
      setAmountOut('');
      setPriceImpact(null);
    }
  }, [amountIn, tokenIn, tokenOut]);

  const handleSwapTokens = () => {
    setTokenIn(tokenOut);
    setTokenOut(tokenIn);
    setAmountIn(amountOut);
    setAmountOut(amountIn);
  };

  const handleSwap = async () => {
    if (!isConnected) return;

    setIsLoading(true);
    try {
      // TODO: Implement actual swap logic with smart contracts
      await new Promise(resolve => setTimeout(resolve, 2000));
      console.log('Swap executed:', {
        tokenIn,
        tokenOut,
        amountIn,
        amountOut,
        slippage,
      });
      alert('Swap successful! (This is a demo)');
    } catch (error) {
      console.error('Swap failed:', error);
      alert('Swap failed! (This is a demo)');
    } finally {
      setIsLoading(false);
    }
  };

  const canSwap = isConnected && tokenIn && tokenOut && amountIn && parseFloat(amountIn) > 0;

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-50 to-gray-100 dark:from-gray-900 dark:to-gray-950">
      <Header />

      <main className="container mx-auto px-4 py-8">
        <div className="max-w-lg mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white dark:bg-gray-900 rounded-3xl shadow-xl p-6 border border-gray-200 dark:border-gray-800"
          >
            {/* Header */}
            <div className="flex items-center justify-between mb-6">
              <h1 className="text-2xl font-bold">Swap</h1>
              <SlippageSettings slippage={slippage} onSlippageChange={setSlippage} />
            </div>

            {/* Input */}
            <SwapInput
              label="You pay"
              token={tokenIn}
              amount={amountIn}
              onAmountChange={setAmountIn}
              onTokenSelect={setTokenIn}
              otherToken={tokenOut}
              showMaxButton={true}
            />

            {/* Swap Button */}
            <div className="flex justify-center -my-3 relative z-10">
              <button
                onClick={handleSwapTokens}
                className="p-3 bg-white dark:bg-gray-900 border-4 border-gray-100 dark:border-gray-950 rounded-xl hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
              >
                <ArrowDownUp className="w-5 h-5" />
              </button>
            </div>

            {/* Output */}
            <SwapInput
              label="You receive"
              token={tokenOut}
              amount={amountOut}
              onAmountChange={setAmountOut}
              onTokenSelect={setTokenOut}
              otherToken={tokenIn}
              readOnly={true}
            />

            {/* Price Info */}
            {tokenIn && tokenOut && amountOut && (
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                className="mt-4 p-4 bg-gray-50 dark:bg-gray-800/50 rounded-xl space-y-2"
              >
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-600 dark:text-gray-400">Rate</span>
                  <span className="font-semibold">
                    1 {tokenIn.symbol} = {(parseFloat(amountOut) / parseFloat(amountIn || '1')).toFixed(4)} {tokenOut.symbol}
                  </span>
                </div>
                {priceImpact !== null && (
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-gray-600 dark:text-gray-400">Price Impact</span>
                    <span className={`font-semibold ${priceImpact > 1 ? 'text-orange-500' : 'text-green-500'}`}>
                      {priceImpact.toFixed(2)}%
                    </span>
                  </div>
                )}
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-600 dark:text-gray-400">Slippage Tolerance</span>
                  <span className="font-semibold">{slippage}%</span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-600 dark:text-gray-400">Network Fee</span>
                  <span className="font-semibold">~$2.50</span>
                </div>
              </motion.div>
            )}

            {/* Swap/Connect Button */}
            <div className="mt-6">
              {!isConnected ? (
                <div className="flex justify-center">
                  <ConnectButton />
                </div>
              ) : !canSwap ? (
                <button
                  disabled
                  className="w-full py-4 bg-gray-200 dark:bg-gray-800 text-gray-500 rounded-xl font-bold cursor-not-allowed"
                >
                  Enter an amount
                </button>
              ) : (
                <button
                  onClick={handleSwap}
                  disabled={isLoading}
                  className="w-full py-4 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white rounded-xl font-bold transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                >
                  {isLoading ? (
                    <>
                      <Loader2 className="w-5 h-5 animate-spin" />
                      Swapping...
                    </>
                  ) : (
                    'Swap'
                  )}
                </button>
              )}
            </div>

            {/* Warning */}
            {priceImpact && priceImpact > 1 && (
              <div className="mt-4 p-4 bg-orange-50 dark:bg-orange-900/20 border border-orange-200 dark:border-orange-800 rounded-xl flex items-start gap-3">
                <AlertCircle className="w-5 h-5 text-orange-600 flex-shrink-0 mt-0.5" />
                <div>
                  <p className="text-sm font-semibold text-orange-800 dark:text-orange-300">
                    High Price Impact
                  </p>
                  <p className="text-sm text-orange-700 dark:text-orange-400">
                    This swap has a price impact of {priceImpact.toFixed(2)}%. Please review carefully.
                  </p>
                </div>
              </div>
            )}
          </motion.div>

          {/* Info Cards */}
          <div className="mt-6 grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="bg-white dark:bg-gray-900 rounded-2xl p-4 border border-gray-200 dark:border-gray-800">
              <h3 className="font-semibold mb-2">Concentrated Liquidity</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                Trade with better prices thanks to concentrated liquidity positions
              </p>
            </div>
            <div className="bg-white dark:bg-gray-900 rounded-2xl p-4 border border-gray-200 dark:border-gray-800">
              <h3 className="font-semibold mb-2">Gas Optimized</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                Bitmap-based tick system ensures minimal gas costs
              </p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
