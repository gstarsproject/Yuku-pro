export interface CreateCheckoutInput {
  bookingId: string; amount: number; currency: 'IDR'; customerEmail?: string;
}
export interface CheckoutResult {
  providerReference: string; checkoutUrl: string; expiresAt?: Date;
}
export interface VerifiedPaymentEvent {
  eventId: string; providerReference: string;
  status: 'PAID' | 'FAILED' | 'EXPIRED';
  amount: number; currency: string;
}
export interface PaymentGateway {
  createCheckout(input: CreateCheckoutInput): Promise<CheckoutResult>;
  verifyWebhook(rawBody: Buffer, headers: Record<string, string>): Promise<VerifiedPaymentEvent>;
}
