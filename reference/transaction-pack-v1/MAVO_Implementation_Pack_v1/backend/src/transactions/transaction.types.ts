export type BookingMode = 'INSTANT' | 'REQUEST';
export type BookingStatus =
  | 'PENDING_PROVIDER' | 'PENDING_PAYMENT' | 'PAID' | 'CONFIRMED'
  | 'IN_SERVICE' | 'COMPLETION_SUBMITTED' | 'COMPLETED'
  | 'CANCELLED' | 'REJECTED' | 'EXPIRED' | 'DISPUTED' | 'REFUNDED';

export const ALLOWED_TRANSITIONS: Record<BookingStatus, BookingStatus[]> = {
  PENDING_PROVIDER: ['PENDING_PAYMENT', 'REJECTED', 'EXPIRED', 'CANCELLED'],
  PENDING_PAYMENT: ['PAID', 'EXPIRED', 'CANCELLED'],
  PAID: ['CONFIRMED', 'CANCELLED', 'DISPUTED'],
  CONFIRMED: ['IN_SERVICE', 'CANCELLED', 'DISPUTED'],
  IN_SERVICE: ['COMPLETION_SUBMITTED', 'DISPUTED'],
  COMPLETION_SUBMITTED: ['COMPLETED', 'DISPUTED'],
  COMPLETED: [],
  CANCELLED: ['REFUNDED'],
  REJECTED: [],
  EXPIRED: [],
  DISPUTED: ['COMPLETED', 'REFUNDED'],
  REFUNDED: [],
};

export function assertTransition(from: BookingStatus, to: BookingStatus) {
  if (!ALLOWED_TRANSITIONS[from]?.includes(to)) {
    throw new Error(`Invalid booking transition: ${from} -> ${to}`);
  }
}
