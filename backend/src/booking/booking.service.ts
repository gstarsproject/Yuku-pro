import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { BookingStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateBookingDto } from './booking.dto';

@Injectable()
export class BookingService {
  constructor(private readonly prisma: PrismaService) {}

  async listMine(userId: string, role: 'CUSTOMER' | 'PROVIDER', limit = 30) {
    const safeLimit = Math.min(100, Math.max(1, limit));
    const where = role === 'CUSTOMER' ? { customerId: userId } : { providerId: userId };
    return this.prisma.booking.findMany({
      where,
      orderBy: { startsAt: 'desc' },
      take: safeLimit,
      include: {
        service: { select: { id: true, title: true, mode: true, city: true, province: true } },
        customer: { select: { id: true, profile: { select: { displayName: true, avatarUrl: true } } } },
        provider: { select: { id: true, profile: { select: { displayName: true, avatarUrl: true } } } },
        payment: { select: { status: true, amount: true, currency: true, paidAt: true } },
        payout: { select: { status: true, netAmount: true, currency: true, paidAt: true } },
      },
    });
  }

  async getMine(userId: string, role: 'CUSTOMER' | 'PROVIDER', bookingId: string) {
    const where = role === 'CUSTOMER'
      ? { id: bookingId, customerId: userId }
      : { id: bookingId, providerId: userId };
    const booking = await this.prisma.booking.findFirst({
      where,
      include: {
        service: true,
        customer: { select: { id: true, profile: { select: { displayName: true, avatarUrl: true } } } },
        provider: { select: { id: true, profile: { select: { displayName: true, avatarUrl: true } } } },
        payment: { select: { status: true, amount: true, currency: true, paidAt: true } },
        payout: { select: { status: true, netAmount: true, currency: true, paidAt: true } },
      },
    });
    if (!booking) throw new NotFoundException('Booking tidak ditemukan.');
    return booking;
  }

  async create(customerId: string, dto: CreateBookingDto) {
    const startsAt = new Date(dto.startsAt), endsAt = new Date(dto.endsAt);
    if (Number.isNaN(startsAt.getTime()) || Number.isNaN(endsAt.getTime()) || !(endsAt > startsAt)) throw new BadRequestException('Rentang waktu booking tidak valid.');
    if (startsAt <= new Date()) throw new BadRequestException('Waktu mulai booking harus di masa depan.');
    const durationMinutes = Math.ceil((endsAt.getTime() - startsAt.getTime()) / 60000);

    return this.prisma.$transaction(async (tx) => {
      const service = await tx.service.findFirst({
        where: { id: dto.serviceId, isPublished: true, provider: { verificationStatus: 'VERIFIED' } },
        include: { provider: true, category: { include: { commissionRule: true } } },
      });
      if (!service) throw new NotFoundException('Layanan tidak tersedia atau provider belum terverifikasi.');
      if (service.priceAmount <= 0) throw new BadRequestException('Harga layanan tidak valid.');

      const conflict = await tx.booking.findFirst({
        where: {
          providerId: service.provider.userId,
          status: { in: ['PENDING_PROVIDER', 'ACCEPTED', 'AWAITING_PAYMENT', 'PAID', 'IN_PROGRESS', 'AWAITING_CONFIRMATION'] },
          startsAt: { lt: endsAt }, endsAt: { gt: startsAt },
        },
      });
      if (conflict) throw new ConflictException('Jadwal provider sudah terisi.');

      const rule = service.category.commissionRule;
      if (!rule?.isActive) throw new BadRequestException('Komisi kategori belum dikonfigurasi. Hubungi admin.');
      const rawFee = Math.floor(service.priceAmount * rule.rateBps / 10000);
      const platformFee = Math.min(rule.maxFee ?? Number.MAX_SAFE_INTEGER, Math.max(rule.minFee, rawFee));
      const travelFee = dto.travelFee ?? 0;
      const totalAmount = service.priceAmount + platformFee + travelFee;

      return tx.booking.create({
        data: {
          customerId, providerId: service.provider.userId, serviceId: service.id,
          status: dto.bookingMode === 'INSTANT' ? BookingStatus.AWAITING_PAYMENT : BookingStatus.PENDING_PROVIDER,
          startsAt, endsAt, durationMinutes, attendeeCount: dto.attendeeCount,
          serviceMode: service.mode, currency: service.currency,
          serviceAmount: service.priceAmount, platformFee, travelFee, totalAmount,
          customerNote: dto.customerNote,
        },
      });
    }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
  }

  async providerDecision(providerUserId: string, bookingId: string, accept: boolean) {
    const booking = await this.prisma.booking.findFirst({ where: { id: bookingId, providerId: providerUserId } });
    if (!booking) throw new NotFoundException('Booking tidak ditemukan.');
    if (booking.status !== 'PENDING_PROVIDER') throw new BadRequestException('Booking bukan menunggu persetujuan.');
    const changed = await this.prisma.booking.updateMany({
      where: { id: bookingId, providerId: providerUserId, status: 'PENDING_PROVIDER' },
      data: { status: accept ? 'AWAITING_PAYMENT' : 'REJECTED' },
    });
    if (changed.count !== 1) throw new ConflictException('Booking sudah diproses atau statusnya berubah.');
    return this.prisma.booking.findUnique({ where: { id: bookingId } });
  }

  async start(providerUserId: string, bookingId: string) {
    const booking = await this.prisma.booking.findFirst({ where: { id: bookingId, providerId: providerUserId } });
    if (!booking) throw new NotFoundException('Booking tidak ditemukan.');
    if (booking.status !== 'PAID') throw new BadRequestException('Booking harus sudah dibayar sebelum dimulai.');
    const changed = await this.prisma.booking.updateMany({ where: { id: bookingId, providerId: providerUserId, status: 'PAID' }, data: { status: 'IN_PROGRESS' } });
    if (changed.count !== 1) throw new ConflictException('Booking sudah diproses atau statusnya berubah.');
    return this.prisma.booking.findUnique({ where: { id: bookingId } });
  }

  async complete(providerUserId: string, bookingId: string) {
    return this.prisma.$transaction(async (tx) => {
      const booking = await tx.booking.findFirst({ where: { id: bookingId, providerId: providerUserId }, include: { payment: true } });
      if (!booking) throw new NotFoundException('Booking tidak ditemukan.');
      if (booking.status !== 'IN_PROGRESS' || booking.payment?.status !== 'SUCCEEDED') {
        throw new BadRequestException('Hanya pesanan berjalan yang sudah dibayar dapat diselesaikan.');
      }
      const changed = await tx.booking.updateMany({ where: { id: bookingId, providerId: providerUserId, status: 'IN_PROGRESS' }, data: { status: 'AWAITING_CONFIRMATION' } });
      if (changed.count !== 1) throw new ConflictException('Booking sudah diproses atau statusnya berubah.');
      const completed = await tx.booking.findUnique({ where: { id: bookingId } });
      const net = booking.serviceAmount - booking.platformFee;
      await tx.providerPayout.upsert({
        where: { bookingId },
        create: { bookingId, providerUserId, grossAmount: booking.serviceAmount, platformFee: booking.platformFee, netAmount: net, status: 'PENDING_RELEASE' },
        update: { status: 'PENDING_RELEASE', releasedAt: null },
      });
      return completed;
    });
  }

  async confirmByCustomer(customerId: string, bookingId: string) {
    return this.prisma.$transaction(async (tx) => {
      const booking = await tx.booking.findFirst({ where: { id: bookingId, customerId }, include: { payment: true, payout: true } });
      if (!booking) throw new NotFoundException('Booking tidak ditemukan.');
      if (booking.status !== 'AWAITING_CONFIRMATION' || booking.payment?.status !== 'SUCCEEDED') {
        throw new BadRequestException('Booking belum menunggu konfirmasi customer.');
      }
      const changed = await tx.booking.updateMany({ where: { id: bookingId, customerId, status: 'AWAITING_CONFIRMATION' }, data: { status: 'COMPLETED' } });
      if (changed.count !== 1) throw new ConflictException('Status booking sudah berubah. Muat ulang halaman.');
      const net = booking.serviceAmount - booking.platformFee;
      await tx.providerPayout.upsert({
        where: { bookingId },
        create: { bookingId, providerUserId: booking.providerId, grossAmount: booking.serviceAmount, platformFee: booking.platformFee, netAmount: net, status: 'READY', releasedAt: new Date() },
        update: { status: 'READY', releasedAt: new Date() },
      });
      const existingLedger = await tx.ledgerEntry.findFirst({ where: { bookingId, accountRef: `provider:${booking.providerId}` } });
      if (!existingLedger) {
        await tx.ledgerEntry.createMany({ data: [
          { accountRef: `provider:${booking.providerId}`, bookingId, entryType: 'CREDIT', amount: net, currency: booking.currency, description: 'Pendapatan provider setelah konfirmasi customer' },
          { accountRef: 'platform:revenue', bookingId, entryType: 'CREDIT', amount: booking.platformFee, currency: booking.currency, description: 'Komisi platform MAVO' },
        ] });
      }
      return tx.booking.findUnique({ where: { id: bookingId } });
    });
  }
}
