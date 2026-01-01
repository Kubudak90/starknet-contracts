'use client';

import { useState } from 'react';
import * as Dialog from '@radix-ui/react-dialog';
import { Search, X, ChevronDown } from 'lucide-react';
import { Token } from '@/lib/types/token';
import { getTokensByChainId } from '@/lib/constants/tokens';
import { useChainId } from 'wagmi';

interface TokenSelectorProps {
  selectedToken: Token | null;
  onSelectToken: (token: Token) => void;
  otherToken?: Token | null;
}

export function TokenSelector({ selectedToken, onSelectToken, otherToken }: TokenSelectorProps) {
  const [open, setOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const chainId = useChainId();

  const tokens = getTokensByChainId(chainId);

  const filteredTokens = tokens.filter((token) => {
    const query = searchQuery.toLowerCase();
    return (
      token.symbol.toLowerCase().includes(query) ||
      token.name.toLowerCase().includes(query) ||
      token.address.toLowerCase().includes(query)
    );
  }).filter((token) => {
    // Don't show the token that's selected in the other input
    return !otherToken || token.address !== otherToken.address;
  });

  const handleSelectToken = (token: Token) => {
    onSelectToken(token);
    setOpen(false);
    setSearchQuery('');
  };

  return (
    <Dialog.Root open={open} onOpenChange={setOpen}>
      <Dialog.Trigger asChild>
        <button className="flex items-center gap-2 px-3 py-2 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 rounded-xl transition-colors">
          {selectedToken ? (
            <>
              {selectedToken.logoURI && (
                <img
                  src={selectedToken.logoURI}
                  alt={selectedToken.symbol}
                  className="w-6 h-6 rounded-full"
                />
              )}
              <span className="font-semibold">{selectedToken.symbol}</span>
            </>
          ) : (
            <span className="text-gray-500">Select token</span>
          )}
          <ChevronDown className="w-4 h-4" />
        </button>
      </Dialog.Trigger>

      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/50 backdrop-blur-sm" />
        <Dialog.Content className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md bg-white dark:bg-gray-900 rounded-2xl shadow-xl p-6 max-h-[80vh] flex flex-col">
          <div className="flex items-center justify-between mb-4">
            <Dialog.Title className="text-xl font-bold">Select a token</Dialog.Title>
            <Dialog.Close asChild>
              <button className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors">
                <X className="w-5 h-5" />
              </button>
            </Dialog.Close>
          </div>

          <div className="relative mb-4">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search by name or address"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-3 bg-gray-100 dark:bg-gray-800 rounded-xl outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div className="flex-1 overflow-y-auto -mx-6 px-6">
            {filteredTokens.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                No tokens found
              </div>
            ) : (
              <div className="space-y-1">
                {filteredTokens.map((token) => (
                  <button
                    key={token.address}
                    onClick={() => handleSelectToken(token)}
                    className="w-full flex items-center gap-3 p-3 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-xl transition-colors"
                  >
                    <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-500 rounded-full flex items-center justify-center text-white font-bold">
                      {token.symbol.substring(0, 2)}
                    </div>
                    <div className="flex-1 text-left">
                      <div className="font-semibold">{token.symbol}</div>
                      <div className="text-sm text-gray-500">{token.name}</div>
                    </div>
                    {selectedToken?.address === token.address && (
                      <div className="w-2 h-2 bg-blue-500 rounded-full" />
                    )}
                  </button>
                ))}
              </div>
            )}
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
