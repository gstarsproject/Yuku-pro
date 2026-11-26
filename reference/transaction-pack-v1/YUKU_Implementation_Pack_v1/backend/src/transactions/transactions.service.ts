import { Injectable, ConflictException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../shared/prisma.service';
import { CreateBookingDto } from './create-booking.dto';
import { calculateSplit } from './commission';

@Injectable()
export class TransactionsService {
  constructor(private readonly prisma: PrismaService) {}

  async createBooking(customerId: string, dto: CreateBookingDto) {
    const service = await this.prisma.service.findFirst({
      where: { id: dto.serviceId, isActive: true, provider: { user: { isActive: true } } },
      include: { category: true, provider: true },
    });
    if (!service) throw new BadRequestException('Service unavailable');

    const start = new Date(dto.scheduledStartAt);
    if (Number.isNaN(start.getTime()) || start <= new Date()) {
      throw new BadRequestException('Booking time must be in the future');
    }
    const end = new Date(start.getTime() + service.durationMins * 60_000);
    const split = calculateSplit(Number(service.price), service.category.commissionBps);

    // Production implementation must perform overlap check + booking insert in a
    // serializable transaction and use a DB exclusion constraint/advisory lock.
    const overlap = await this.prisma.booking.findFirst({
      where: {
        providerId: service.providerId,
        status: { in: ['PENDING_PROVIDER','PENDING_PAYMENT','PAID','CONFIRMED','IN_SERVICE'] },
        scheduledStartAt: { lt: end },
        scheduledEndAt: { gt: start },
      },
    });
    if (overlap) throw new ConflictException('Provider is not available at this time');

    const booking = await this.prisma.booking.create({
      data: {
        bookingCode: `YKU-${Date.now()}-${Math.floor(Math.random()*10000)}`,
        customerId, providerId: service.providerId, serviceId: service.id,
        mode: dto.mode,
        status: dto.mode === 'REQUEST' ? 'PENDING_PROVIDER' : 'PENDING_PAYMENT',
        scheduledStartAt: start, scheduledEndAt: end,
        locationText: dto.locationText, customerNote: dto.customerNote,
        servicePrice: service.price, commissionBps: service.category.commissionBps,
        commissionAmount: split.commission, providerNetAmount: split.providerNet,
      },
    });
    return booking;
  }

  async providerRespond(providerUserId: string, bookingId: string, accept: boolean) {
    const provider = await this.prisma.provider.findUnique({ where: { userId: providerUserId } });
    if (!provider) throw new BadRequestException('Provider profile not found');
    const booking = await this.prisma.booking.findFirst({
      where: { id: bookingId, providerId: provider.id, status: 'PENDING_PROVIDER' },
    });
    if (!booking) throw new ConflictException('Booking is no longer actionable');
    return this.prisma.booking.update({
      where: { id: bookingId },
      data: { status: accept ? 'PENDING_PAYMENT' : 'REJECTED' },
    });
  }

  async submitCompletion(providerUserId: string, bookingId: string) {
    const provider = await this.prisma.provider.findUnique({ where: { userId: providerUserId } });
    if (!provider) throw new BadRequestException('Provider profile not found');
    const booking = await this.prisma.booking.findFirst({
      where: { id: bookingId, providerId: provider.id, status: 'IN_SERVICE' },
    });
    if (!booking) throw new ConflictException('Booking cannot be completed from current state');
    return this.prisma.booking.update({
      where: { id: bookingId }, data: { status: 'COMPLETION_SUBMITTED' },
    });
  }

  async customerConfirmCompletion(customerId: string, bookingId: string) {
    const booking = await this.prisma.booking.findFirst({
      where: { id: bookingId, customerId, status: 'COMPLETION_SUBMITTED' },
    });
    if (!booking) throw new ConflictException('Booking is not awaiting your confirmation');

    // Production: wrap status update + immutable ledger creation in one DB transaction.
    return this.prisma.$transaction(async (tx) => {
      const completed = await tx.booking.update({
        where: { id: bookingId }, data: { status: 'COMPLETED' },
      });
      await tx.ledgerEntry.createMany({ data: [
        { bookingId, providerId: booking.providerId, type: 'PROVIDER_EARNING',
          amount: booking.providerNetAmount, reference: `earning:${bookingId}`,
          description: 'Provider earning released after customer completion confirmation' },
        { bookingId, type: 'PLATFORM_COMMISSION',
          amount: booking.commissionAmount, reference: `commission:${bookingId}`,
          description: 'Platform commission' },
      ]});
      return completed;
    });
  }
}
