import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { createHash } from 'crypto';
import axios from 'axios';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class PaymentService {
  constructor(private readonly prisma: PrismaService) {}

  async createCheckout(customerId: string, bookingId: string) {
    const booking = await this.prisma.booking.findFirst({ where: { id: bookingId, customerId }, include: { customer: { include: { profile: true } } } });
    if (!booking) throw new NotFoundException('Booking tidak ditemukan.');
    if (!['AWAITING_PAYMENT'].includes(booking.status)) throw new BadRequestException('Booking belum siap dibayar.');
    const serverKey = process.env.MIDTRANS_SERVER_KEY;
    if (!serverKey || serverKey === 'replace_me') throw new BadRequestException('Konfigurasi Midtrans Sandbox belum diisi.');
    const base = process.env.MIDTRANS_IS_PRODUCTION === 'true' ? 'https://api.midtrans.com' : 'https://api.sandbox.midtrans.com';
    const orderId = `MAVO-${booking.id}`;
    const response = await axios.post(`${base}/v2/charge`, {
      payment_type: 'bank_transfer',
      transaction_details: { order_id: orderId, gross_amount: booking.totalAmount },
      customer_details: { first_name: booking.customer.profile?.displayName ?? 'MAVO Customer', email: booking.customer.email ?? undefined, phone: booking.customer.phone ?? undefined },
      bank_transfer: { bank: 'bca' },
    }, { auth: { username: serverKey, password: '' } });

    await this.prisma.payment.upsert({
      where: { bookingId },
      create: { bookingId, gateway: 'MIDTRANS', gatewayReference: orderId, amount: booking.totalAmount, status: 'PENDING' },
      update: { gatewayReference: orderId, status: 'PENDING' },
    });
    return { orderId, gateway: 'MIDTRANS', transaction: response.data };
  }

  async handleMidtransWebhook(payload: any) {
    const key = process.env.MIDTRANS_SERVER_KEY;
    if (!key) throw new BadRequestException('Webhook key belum dikonfigurasi.');
    const expected = createHash('sha512').update(`${payload.order_id}${payload.status_code}${payload.gross_amount}${key}`).digest('hex');
    if (expected !== payload.signature_key) throw new BadRequestException('Signature webhook tidak valid.');
    const eventKey = `${payload.order_id}:${payload.transaction_status}:${payload.transaction_id}`;
    const existing = await this.prisma.paymentWebhookEvent.findUnique({ where: { eventKey } });
    if (existing) return { received: true, duplicate: true };

    await this.prisma.$transaction(async (tx) => {
      await tx.paymentWebhookEvent.create({ data: { gateway: 'MIDTRANS', eventKey, gatewayOrderId: payload.order_id, eventType: payload.transaction_status, payload } });
      const payment = await tx.payment.findFirst({ where: { gatewayReference: payload.order_id }, include: { booking: true } });
      if (!payment) throw new NotFoundException('Payment untuk order ini tidak ditemukan.');
      const paid = ['settlement', 'capture'].includes(payload.transaction_status);
      const failed = ['deny', 'cancel', 'expire'].includes(payload.transaction_status);
      await tx.payment.update({ where: { id: payment.id }, data: { status: paid ? 'SUCCEEDED' : failed ? (payload.transaction_status === 'expire' ? 'EXPIRED' : 'FAILED') : 'PENDING', paidAt: paid ? new Date() : null } });
      if (paid) await tx.booking.update({ where: { id: payment.bookingId }, data: { status: 'PAID' } });
      if (failed) await tx.booking.update({ where: { id: payment.bookingId }, data: { status: 'AWAITING_PAYMENT' } });
      await tx.paymentWebhookEvent.update({ where: { eventKey }, data: { processedAt: new Date() } });
    });
    return { received: true };
  }
}
