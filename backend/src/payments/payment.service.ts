import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { createHash, timingSafeEqual } from 'crypto';
import axios from 'axios';
import { PrismaService } from '../prisma/prisma.service';

type MidtransNotification = {
  order_id: string;
  status_code: string;
  gross_amount: string;
  signature_key: string;
  transaction_status: string;
  transaction_id: string;
};

@Injectable()
export class PaymentService {
  constructor(private readonly prisma: PrismaService) {}

  async createCheckout(customerId: string, bookingId: string) {
    const booking = await this.prisma.booking.findFirst({ where: { id: bookingId, customerId }, include: { customer: { include: { profile: true } } } });
    if (!booking) throw new NotFoundException('Booking tidak ditemukan.');
    if (booking.status !== 'AWAITING_PAYMENT') throw new BadRequestException('Booking belum siap dibayar.');
    const serverKey = process.env.MIDTRANS_SERVER_KEY;
    if (!serverKey || serverKey === 'replace_me') throw new BadRequestException('Konfigurasi Midtrans Sandbox belum diisi.');
    const base = process.env.MIDTRANS_IS_PRODUCTION === 'true' ? 'https://api.midtrans.com' : 'https://api.sandbox.midtrans.com';
    const orderId = `MAVO-${booking.id}`;
    const response = await axios.post(`${base}/v2/charge`, {
      payment_type: 'bank_transfer',
      transaction_details: { order_id: orderId, gross_amount: booking.totalAmount },
      customer_details: { first_name: booking.customer.profile?.displayName ?? 'MAVO Customer', email: booking.customer.email ?? undefined, phone: booking.customer.phone ?? undefined },
      bank_transfer: { bank: 'bca' },
    }, { auth: { username: serverKey, password: '' }, timeout: 15000 });

    await this.prisma.payment.upsert({
      where: { bookingId },
      create: { bookingId, gateway: 'MIDTRANS', gatewayReference: orderId, amount: booking.totalAmount, currency: booking.currency, status: 'PENDING' },
      update: { gatewayReference: orderId, amount: booking.totalAmount, currency: booking.currency, status: 'PENDING' },
    });
    return { orderId, gateway: 'MIDTRANS', transaction: response.data };
  }

  async handleMidtransWebhook(input: unknown) {
    const payload = input as Partial<MidtransNotification> | null;
    const key = process.env.MIDTRANS_SERVER_KEY;
    if (!key) throw new BadRequestException('Webhook key belum dikonfigurasi.');
    if (!payload || typeof payload.order_id !== 'string' ||
        typeof payload.status_code !== 'string' || typeof payload.gross_amount !== 'string' ||
        typeof payload.signature_key !== 'string' || typeof payload.transaction_status !== 'string' ||
        typeof payload.transaction_id !== 'string') {
      throw new BadRequestException('Payload webhook tidak lengkap.');
    }

    const expected = createHash('sha512').update(`${payload.order_id}${payload.status_code}${payload.gross_amount}${key}`).digest();
    const received = Buffer.from(payload.signature_key, 'hex');
    if (received.length !== expected.length || !timingSafeEqual(expected, received)) {
      throw new BadRequestException('Signature webhook tidak valid.');
    }

    const orderId = payload.order_id;
    const transactionStatus = payload.transaction_status;
    const transactionId = payload.transaction_id;
    const statusCode = payload.status_code;
    const grossAmount = payload.gross_amount;
    const signatureKey = payload.signature_key;
    const eventKey = `${orderId}:${transactionStatus}:${transactionId}`;
    return this.prisma.$transaction(async (tx) => {
      const existing = await tx.paymentWebhookEvent.findUnique({ where: { eventKey } });
      if (existing?.processedAt) return { received: true, duplicate: true };

      const payment = await tx.payment.findFirst({
        where: { gatewayReference: orderId, gateway: 'MIDTRANS' },
        include: { booking: true },
      });
      if (!payment) throw new NotFoundException('Payment untuk order ini tidak ditemukan.');
      if (Number(grossAmount) !== payment.amount) {
        throw new BadRequestException('Nominal webhook tidak sesuai dengan nominal booking.');
      }

      if (!existing) {
        await tx.paymentWebhookEvent.create({
          data: { gateway: 'MIDTRANS', eventKey, gatewayOrderId: orderId, eventType: transactionStatus, payload: input as object },
        });
      }

      const paid = ['settlement', 'capture'].includes(transactionStatus);
      const failed = ['deny', 'cancel', 'expire'].includes(payload.transaction_status);

      // A successful payment is terminal here: delayed pending/failed notifications
      // must never downgrade a paid booking or payment.
      if (payment.status !== 'SUCCEEDED' && payment.status !== 'REFUNDED') {
        if (paid) {
          await tx.payment.update({ where: { id: payment.id }, data: { status: 'SUCCEEDED', paidAt: payment.paidAt ?? new Date() } });
          await tx.booking.updateMany({
            where: { id: payment.bookingId, status: 'AWAITING_PAYMENT' },
            data: { status: 'PAID' },
          });
        } else if (failed) {
          await tx.payment.update({ where: { id: payment.id }, data: { status: transactionStatus === 'expire' ? 'EXPIRED' : 'FAILED' } });
          await tx.booking.updateMany({
            where: { id: payment.bookingId, status: 'AWAITING_PAYMENT' },
            data: { status: 'AWAITING_PAYMENT' },
          });
        }
      }

      await tx.paymentWebhookEvent.update({ where: { eventKey }, data: { processedAt: new Date() } });
      return { received: true, duplicate: false };
    });
  }
}
