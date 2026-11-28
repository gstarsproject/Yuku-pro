import { Controller, Get, UseGuards, Query, DefaultValuePipe, ParseIntPipe } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AdminAuthGuard } from '../auth/admin-auth.guard';

@Controller('admin')
@UseGuards(AdminAuthGuard)
export class AdminController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('overview')
  async overview() {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const [totalUsers, activeProviders, bookingsToday, openDisputes] =
      await Promise.all([
        this.prisma.user.count(),
        this.prisma.user.count({
          where: { role: 'PROVIDER', status: 'ACTIVE' },
        }),
        this.prisma.booking.count({
          where: { createdAt: { gte: startOfDay } },
        }),
        this.prisma.dispute.count({
          where: { status: 'OPEN' },
        }),
      ]);

    return {
      totalUsers,
      activeProviders,
      bookingsToday,
      openDisputes,
      generatedAt: new Date().toISOString(),
    };
  }
  @Get('verification/pending')
  async pendingVerification(@Query('limit', new DefaultValuePipe(30), ParseIntPipe) limit: number) {
    return this.prisma.verificationDocument.findMany({
      where: { status: 'PENDING' },
      orderBy: { createdAt: 'asc' },
      take: Math.min(100, Math.max(1, limit)),
      select: {
        id: true, documentType: true, storageKey: true, status: true, createdAt: true,
        user: { select: { id: true, email: true, phone: true, profile: { select: { displayName: true } }, provider: { select: { verificationStatus: true } } } },
      },
    });
  }

  @Get('disputes')
  async disputes(@Query('limit', new DefaultValuePipe(30), ParseIntPipe) limit: number) {
    return this.prisma.dispute.findMany({
      where: { status: { in: ['OPEN', 'UNDER_REVIEW'] } },
      orderBy: { createdAt: 'asc' },
      take: Math.min(100, Math.max(1, limit)),
      include: {
        booking: { select: { id: true, status: true, startsAt: true, endsAt: true, totalAmount: true, currency: true } },
      },
    });
  }
}
