'use client';

import { useState } from 'react';
import * as Dialog from '@radix-ui/react-dialog';
import { Settings, X } from 'lucide-react';

interface SlippageSettingsProps {
  slippage: number;
  onSlippageChange: (slippage: number) => void;
}

const PRESET_SLIPPAGES = [0.1, 0.5, 1.0];

export function SlippageSettings({ slippage, onSlippageChange }: SlippageSettingsProps) {
  const [open, setOpen] = useState(false);
  const [customSlippage, setCustomSlippage] = useState('');

  const handlePresetClick = (value: number) => {
    onSlippageChange(value);
    setCustomSlippage('');
  };

  const handleCustomSlippageChange = (value: string) => {
    setCustomSlippage(value);
    const numValue = parseFloat(value);
    if (!isNaN(numValue) && numValue >= 0 && numValue <= 50) {
      onSlippageChange(numValue);
    }
  };

  const isCustom = !PRESET_SLIPPAGES.includes(slippage);

  return (
    <Dialog.Root open={open} onOpenChange={setOpen}>
      <Dialog.Trigger asChild>
        <button className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors">
          <Settings className="w-5 h-5" />
        </button>
      </Dialog.Trigger>

      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/50 backdrop-blur-sm" />
        <Dialog.Content className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md bg-white dark:bg-gray-900 rounded-2xl shadow-xl p-6">
          <div className="flex items-center justify-between mb-6">
            <Dialog.Title className="text-xl font-bold">Settings</Dialog.Title>
            <Dialog.Close asChild>
              <button className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors">
                <X className="w-5 h-5" />
              </button>
            </Dialog.Close>
          </div>

          <div className="space-y-4">
            <div>
              <div className="flex items-center justify-between mb-3">
                <label className="font-semibold">Slippage Tolerance</label>
                <span className="text-sm text-gray-500">{slippage}%</span>
              </div>

              <div className="grid grid-cols-4 gap-2 mb-2">
                {PRESET_SLIPPAGES.map((preset) => (
                  <button
                    key={preset}
                    onClick={() => handlePresetClick(preset)}
                    className={`py-2 px-3 rounded-lg font-semibold transition-colors ${
                      slippage === preset
                        ? 'bg-blue-600 text-white'
                        : 'bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700'
                    }`}
                  >
                    {preset}%
                  </button>
                ))}
                <div className="relative">
                  <input
                    type="text"
                    placeholder="Custom"
                    value={customSlippage}
                    onChange={(e) => handleCustomSlippageChange(e.target.value)}
                    className={`w-full py-2 px-3 rounded-lg text-center font-semibold outline-none transition-colors ${
                      isCustom
                        ? 'bg-blue-600 text-white'
                        : 'bg-gray-100 dark:bg-gray-800'
                    }`}
                  />
                </div>
              </div>

              {slippage > 5 && (
                <div className="p-3 bg-orange-100 dark:bg-orange-900/20 border border-orange-300 dark:border-orange-700 rounded-lg">
                  <p className="text-sm text-orange-800 dark:text-orange-300">
                    High slippage tolerance! Your transaction may be frontrun.
                  </p>
                </div>
              )}
              {slippage < 0.1 && (
                <div className="p-3 bg-yellow-100 dark:bg-yellow-900/20 border border-yellow-300 dark:border-yellow-700 rounded-lg">
                  <p className="text-sm text-yellow-800 dark:text-yellow-300">
                    Low slippage tolerance. Your transaction may fail.
                  </p>
                </div>
              )}
            </div>

            <div className="pt-4 border-t border-gray-200 dark:border-gray-800">
              <div className="flex items-center justify-between">
                <label className="font-semibold">Transaction Deadline</label>
                <div className="flex items-center gap-2">
                  <input
                    type="number"
                    defaultValue={20}
                    className="w-20 py-2 px-3 bg-gray-100 dark:bg-gray-800 rounded-lg text-center outline-none"
                  />
                  <span className="text-gray-500">minutes</span>
                </div>
              </div>
            </div>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
