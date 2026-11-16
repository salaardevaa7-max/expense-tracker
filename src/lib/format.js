export function fmt(n) {
  const v = Math.round((n || 0) * 100) / 100;
  return '₹' + v.toLocaleString('en-IN', { maximumFractionDigits: v % 1 ? 2 : 0 });
}
