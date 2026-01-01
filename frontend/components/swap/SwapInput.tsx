'use client';

import { Token } from '@/lib/types/token';
import { TokenSelector } from './TokenSelector';
import { useAccount, useBalance } from 'wagmi';

interface SwapInputProps {
  label: string;
  token: Token | null;
  amount: string;
  onAmountChange: (amount: string) => void;
  onTokenSelect: (token: Token) => void;
  otherToken?: Token | null;
  readOnly?: boolean;
  showMaxButton?: boolean;
}

export function SwapInput({
  label,
  token,
  amount,
  onAmountChange,
  onTokenSelect,
  otherToken,
  readOnly = false,
  showMaxButton = false,
}: SwapInputProps) {
  const { address } = useAccount();
  const { data: balance } = useBalance({
    address,
    token: token?.address === '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'
      ? undefined
      : token?.address as `0x${string}`,
  });

  const handleMaxClick = () => {
    if (balance) {
      onAmountChange(balance.formatted);
    }
  };

  const handleAmountChange = (value: string) => {
    // Only allow numbers and single decimal point
    if (value === '' || /^\d*\.?\d*$/.test(value)) {
      onAmountChange(value);
    }
  };

  return (
    <div className="bg-gray-50 dark:bg-gray-800/50 rounded-2xl p-4">
      <div className="flex items-center justify-between mb-2">
        <span className="text-sm text-gray-600 dark:text-gray-400">{label}</span>
        {address && token && balance && (
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-600 dark:text-gray-400">
              Balance: {parseFloat(balance.formatted).toFixed(4)}
            </span>
            {showMaxButton && (
              <button
                onClick={handleMaxClick}
                className="text-xs font-semibold text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300"
              >
                MAX
              </button>
            )}
          </div>
        )}
      </div>

      <div className="flex items-center gap-3">
        <input
          type="text"
          value={amount}
          onChange={(e) => handleAmountChange(e.target.value)}
          placeholder="0.0"
          readOnly={readOnly}
          className="flex-1 text-3xl font-semibold bg-transparent outline-none"
        />
        <TokenSelector
          selectedToken={token}
          onSelectToken={onTokenSelect}
          otherToken={otherToken}
        />
      </div>

      {amount && token && (
        <div className="mt-2 text-sm text-gray-500">
          ≈ $0.00
        </div>
      )}
    </div>
  );
}
