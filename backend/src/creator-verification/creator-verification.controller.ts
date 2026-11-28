import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { IsString, MaxLength, MinLength } from 'class-validator';
import { AuthenticatedRequest, UserAuthGuard } from '../auth/user-auth.guard';
import { PrismaService } from '../prisma/prisma.service';

class SubmitCreatorVerificationDto {
  @IsString() @MinLength(2) @MaxLength(80) creatorName!: string;
  @IsString() @MinLength(2) @MaxLength(80) handle!: string;
  @IsString() @MinLength(2) @MaxLength(80) category!: string;
  @IsString() @MinLength(20) @MaxLength(1000) reason!: string;
}

@Controller('creator-verification')
@UseGuards(UserAuthGuard)
export class CreatorVerificationController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('me')
  async status(@Req() req: AuthenticatedRequest) {
    const data = await this.prisma.creatorVerificationRequest.findUnique({ where: { userId: req.user!.sub } });
    return { success: true, data };
  }

  @Post()
  async submit(@Req() req: AuthenticatedRequest, @Body() body: SubmitCreatorVerificationDto) {
    const userId = req.user!.sub;
    const existing = await this.prisma.creatorVerificationRequest.findUnique({ where: { userId } });
    if (existing?.status === 'PENDING') return { success: true, data: existing, message: 'Pengajuan sedang ditinjau.' };
    if (existing?.status === 'VERIFIED') return { success: true, data: existing, message: 'Akun kreator sudah terverifikasi.' };
    const data = await this.prisma.creatorVerificationRequest.upsert({
      where: { userId },
      create: { userId, creatorName: body.creatorName.trim(), handle: body.handle.trim().replace(/^@/, ''), category: body.category.trim(), reason: body.reason.trim(), documentKeys: [], status: 'PENDING' },
      update: { creatorName: body.creatorName.trim(), handle: body.handle.trim().replace(/^@/, ''), category: body.category.trim(), reason: body.reason.trim(), documentKeys: [], status: 'PENDING', rejectionReason: null, submittedAt: new Date(), reviewedAt: null, reviewedById: null },
    });
    return { success: true, data };
  }
}
