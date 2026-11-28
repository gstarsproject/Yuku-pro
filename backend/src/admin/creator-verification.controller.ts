import { Body, Controller, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';
import { AdminAuthGuard } from '../auth/admin-auth.guard';
import { PrismaService } from '../prisma/prisma.service';
import { Request } from 'express';

class ReviewCreatorDto {
  @IsIn(['VERIFIED', 'REJECTED']) status!: 'VERIFIED' | 'REJECTED';
  @IsOptional() @IsString() @MaxLength(1000) rejectionReason?: string;
}

type AdminRequest = Request & { user?: { sub: string } };
@Controller('admin/creators')
@UseGuards(AdminAuthGuard)
export class AdminCreatorVerificationController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('pending')
  async pending() {
    const data = await this.prisma.creatorVerificationRequest.findMany({ where: { status: 'PENDING' }, orderBy: { submittedAt: 'asc' }, include: { user: { include: { profile: true } } } });
    return { success: true, data: data.map(({ user, ...item }) => ({ ...item, user: { id: user.id, email: user.email, displayName: user.profile?.displayName ?? null } })) };
  }

  @Post(':id/review')
  async review(@Param('id') id: string, @Body() body: ReviewCreatorDto, @Req() req: AdminRequest) {
    const current = await this.prisma.creatorVerificationRequest.findUnique({ where: { id } });
    if (!current || current.status !== 'PENDING') return { success: false, message: 'Pengajuan tidak ditemukan atau sudah ditinjau.' };
    const data = await this.prisma.creatorVerificationRequest.update({ where: { id }, data: { status: body.status, rejectionReason: body.status === 'REJECTED' ? (body.rejectionReason?.trim() || 'Dokumen atau informasi belum memenuhi persyaratan.') : null, reviewedAt: new Date(), reviewedById: req.user!.sub } });
    return { success: true, data };
  }
}
