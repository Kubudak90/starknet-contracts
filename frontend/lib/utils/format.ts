export function formatNumber(value: string | number, decimals: number = 2): string {
  const num = typeof value === 'string' ? parseFloat(value) : value;
  if (isNaN(num)) return '0';

  if (num === 0) return '0';
  if (num < 0.01) return '<0.01';

  return num.toLocaleString('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: decimals,
  });
}

export function formatCurrency(value: string | number): string {
  const num = typeof value === 'string' ? parseFloat(value) : value;
  if (isNaN(num)) return '$0.00';

  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(num);
}

export function formatTokenAmount(amount: string, decimals: number): string {
  const num = parseFloat(amount);
  if (isNaN(num)) return '0';

  if (num === 0) return '0';
  if (num < 1 / Math.pow(10, decimals)) {
    return `<${1 / Math.pow(10, decimals)}`;
  }

  return formatNumber(num, decimals);
}

export function shortenAddress(address: string, chars: number = 4): string {
  return `${address.substring(0, chars + 2)}...${address.substring(address.length - chars)}`;
}
