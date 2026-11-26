import { Controller, Get, UseGuards } from '@nestjs/common';
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
}
