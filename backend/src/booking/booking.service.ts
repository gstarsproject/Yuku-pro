import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { BookingStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateBookingDto } from './booking.dto';

@Injectable()
export class BookingService {
  constructor(private readonly prisma: PrismaService) {}

  async listForUser(userId: string, role: 'CUSTOMER' | 'PROVIDER') {
    const where = role === 'PROVIDER' ? { providerId: userId } : { customerId: userId };
    return this.prisma.booking.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: 100,
      include: {
        service: { select: { id: true, title: true, mode: true, priceUnit: true } },
        customer: { select: { id: true, profile: { select: { displayName: true, avatarUrl: true } } } },
        provider: { select: { id: true, profile: { select: { displayName: true, avatarUrl: true } } } },
        payment: { select: { status: true, amount: true, currency: true } },
      },
    });
  }

  async create(customerId: string, dto: CreateBookingDto) {
    const startsAt = new Date(dto.startsAt), endsAt = new Date(dto.endsAt);
    if (!(endsAt > startsAt)) throw new BadRequestException('Waktu selesai harus setelah waktu mulai.');
    const durationMinutes = Math.ceil((endsAt.getTime() - startsAt.getTime()) / 60000);

    return this.prisma.$transaction(async (tx) => {
      const service = await tx.service.findFirst({
        where: { id: dto.serviceId, isPublished: true, provider: { verificationStatus: 'VERIFIED' } },
        include: { provider: true, category: { include: { commissionRule: true } } },
      });
      if (!service) throw new NotFoundException('Layanan tidak tersedia atau provider belum terverifikasi.');
      if (service.mode === 'ONLINE' && !['ONLINE', 'BOTH'].includes(service.mode)) throw new BadRequestException('Mode layanan tidak sesuai.');

      const conflict = await tx.booking.findFirst({
        where: {
          providerId: service.provider.userId,
          status: { in: ['PENDING_PROVIDER', 'ACCEPTED', 'AWAITING_PAYMENT', 'PAID', 'IN_PROGRESS'] },
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
    return this.prisma.booking.update({
      where: { id: bookingId },
      data: { status: accept ? 'AWAITING_PAYMENT' : 'REJECTED' },
    });
  }

  async start(providerUserId: string, bookingId: string) {
    const booking = await this.prisma.booking.findFirst({ where: { id: bookingId, providerId: providerUserId } });
    if (!booking) throw new NotFoundException('Booking tidak ditemukan.');
    if (booking.status !== 'PAID') throw new BadRequestException('Booking harus sudah dibayar sebelum dimulai.');
    return this.prisma.booking.update({ where: { id: bookingId }, data: { status: 'IN_PROGRESS' } });
  }

  async complete(providerUserId: string, bookingId: string) {
    return this.prisma.$transaction(async (tx) => {
      const booking = await tx.booking.findFirst({ where: { id: bookingId, providerId: providerUserId }, include: { payment: true } });
      if (!booking) throw new NotFoundException('Booking tidak ditemukan.');
      if (booking.status !== 'IN_PROGRESS' || booking.payment?.status !== 'SUCCEEDED') {
        throw new BadRequestException('Hanya pesanan berjalan yang sudah dibayar dapat diselesaikan.');
      }
      const completed = await tx.booking.update({ where: { id: bookingId }, data: { status: 'COMPLETED' } });
      const net = booking.serviceAmount - booking.platformFee;
      await tx.providerPayout.upsert({
        where: { bookingId },
        create: { bookingId, providerUserId, grossAmount: booking.serviceAmount, platformFee: booking.platformFee, netAmount: net, status: 'READY' },
        update: { status: 'READY', releasedAt: new Date() },
      });
      await tx.ledgerEntry.createMany({ data: [
        { accountRef: `provider:${providerUserId}`, bookingId, entryType: 'CREDIT', amount: net, description: 'Pendapatan provider setelah booking selesai' },
        { accountRef: 'platform:revenue', bookingId, entryType: 'CREDIT', amount: booking.platformFee, description: 'Komisi platform YUKU' },
      ]});
      return completed;
    });
  }
}
