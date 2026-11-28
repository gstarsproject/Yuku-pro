import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../shared/prisma.service';

@Injectable()
export class PayoutsService {
  constructor(private readonly prisma: PrismaService) {}

  async requestPayout(providerUserId: string, bookingIds: string[]) {
    const provider = await this.prisma.provider.findUnique({ where: { userId: providerUserId } });
    if (!provider) throw new BadRequestException('Provider profile not found');
    if (!bookingIds.length) throw new BadRequestException('Select eligible earnings');

    return this.prisma.$transaction(async (tx) => {
      const earnings = await tx.ledgerEntry.findMany({
        where: {
          providerId: provider.id, type: 'PROVIDER_EARNING',
          bookingId: { in: bookingIds },
        },
      });
      if (earnings.length !== bookingIds.length) {
        throw new BadRequestException('Some earnings are not eligible');
      }
      const alreadyUsed = await tx.payoutItem.findMany({
        where: { bookingId: { in: bookingIds } },
      });
      if (alreadyUsed.length) throw new BadRequestException('Some earnings are already assigned to a payout');

      const amount = earnings.reduce((sum, e) => sum + Number(e.amount), 0);
      // Bank details must be verified and read from the provider profile, never from the request body.
      if (!provider.payoutBankName || !provider.payoutAccountName || !provider.payoutAccountNumberEncrypted) {
        throw new BadRequestException('Verified payout bank account required');
      }
      const payout = await tx.payout.create({
        data: {
          providerId: provider.id, amount, bankName: provider.payoutBankName,
          accountName: provider.payoutAccountName, accountNumberMasked: '****',
          status: 'PENDING_REVIEW',
          items: { create: earnings.map(e => ({ bookingId: e.bookingId!, amount: e.amount })) },
        },
      });
      return { payoutId: payout.id, amount: payout.amount, status: payout.status };
    });
  }
}
