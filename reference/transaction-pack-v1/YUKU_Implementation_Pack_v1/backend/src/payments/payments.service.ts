import { Injectable, BadRequestException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../shared/prisma.service';
import { PaymentGateway } from './payment-gateway.interface';

@Injectable()
export class PaymentsService {
  constructor(private readonly prisma: PrismaService, private readonly gateway: PaymentGateway) {}

  async createCheckout(customerId: string, bookingId: string, email?: string) {
    const booking = await this.prisma.booking.findFirst({
      where: { id: bookingId, customerId, status: 'PENDING_PAYMENT' },
      include: { payment: true },
    });
    if (!booking) throw new ConflictException('Booking is not payable');
    if (booking.payment) throw new ConflictException('Checkout already exists');

    const result = await this.gateway.createCheckout({
      bookingId, amount: Number(booking.servicePrice), currency: 'IDR', customerEmail: email,
    });
    await this.prisma.payment.create({
      data: {
        bookingId, providerName: 'configured-gateway',
        providerReference: result.providerReference,
        checkoutUrl: result.checkoutUrl, amount: booking.servicePrice,
      },
    });
    return { checkoutUrl: result.checkoutUrl, expiresAt: result.expiresAt };
  }

  async processVerifiedEvent(event: any, payloadHash: string) {
    // Call only after provider signature verification. Use unique eventId for idempotency.
    return this.prisma.$transaction(async (tx) => {
      const seen = await tx.webhookEvent.findUnique({
        where: { provider_eventId: { provider: 'configured-gateway', eventId: event.eventId } },
      });
      if (seen) return { duplicate: true };

      await tx.webhookEvent.create({ data: {
        provider: 'configured-gateway', eventId: event.eventId,
        eventType: event.status, payloadHash, processedAt: new Date(),
      }});

      const payment = await tx.payment.findUnique({
        where: { providerReference: event.providerReference }, include: { booking: true },
      });
      if (!payment) throw new BadRequestException('Unknown payment reference');
      if (Number(payment.amount) !== event.amount || payment.currency !== event.currency) {
        throw new BadRequestException('Payment amount/currency mismatch');
      }
      if (event.status === 'PAID') {
        await tx.payment.update({ where: { id: payment.id }, data: { status: 'PAID', paidAt: new Date() } });
        await tx.booking.update({ where: { id: payment.bookingId }, data: { status: 'PAID' } });
      } else {
        await tx.payment.update({ where: { id: payment.id }, data: { status: event.status } });
      }
      return { processed: true };
    });
  }
}
