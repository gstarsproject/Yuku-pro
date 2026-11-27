/**
 * All rates are stored as basis points in ServiceCategory.commissionBps.
 * Example: 1250 = 12.50%. Do not accept commission from mobile clients.
 */
export function calculateSplit(price: number, commissionBps: number) {
  if (!Number.isSafeInteger(commissionBps) || commissionBps < 0 || commissionBps > 10000) {
    throw new Error('Invalid commission rate');
  }
  if (!Number.isFinite(price) || price <= 0) throw new Error('Invalid service price');
  const commission = Math.round((price * commissionBps) / 10000);
  return { commission, providerNet: price - commission };
}
