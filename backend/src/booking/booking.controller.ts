import { Body, Controller, Param, Post, Req, UseGuards, ForbiddenException } from '@nestjs/common';
import { Request } from 'express';
import { BookingService } from './booking.service';
import { CreateBookingDto } from './booking.dto';
import { UserAuthGuard, AppUser } from '../auth/user-auth.guard';

type AuthRequest = Request & { user: AppUser };

@Controller('bookings')
@UseGuards(UserAuthGuard)
export class BookingController {
  constructor(private readonly service: BookingService) {}

  @Post()
  create(@Req() request: AuthRequest, @Body() dto: CreateBookingDto) {
    if (request.user.role !== 'CUSTOMER') throw new ForbiddenException('Hanya customer yang dapat membuat booking');
    return this.service.create(request.user.sub, dto);
  }

  @Post(':id/accept')
  accept(@Req() request: AuthRequest, @Param('id') id: string) {
    if (request.user.role !== 'PROVIDER') throw new ForbiddenException('Aksi khusus provider');
    return this.service.providerDecision(request.user.sub, id, true);
  }

  @Post(':id/reject')
  reject(@Req() request: AuthRequest, @Param('id') id: string) {
    if (request.user.role !== 'PROVIDER') throw new ForbiddenException('Aksi khusus provider');
    return this.service.providerDecision(request.user.sub, id, false);
  }

  @Post(':id/start')
  start(@Req() request: AuthRequest, @Param('id') id: string) {
    if (request.user.role !== 'PROVIDER') throw new ForbiddenException('Aksi khusus provider');
    return this.service.start(request.user.sub, id);
  }

  @Post(':id/complete')
  complete(@Req() request: AuthRequest, @Param('id') id: string) {
    if (request.user.role !== 'PROVIDER') throw new ForbiddenException('Aksi khusus provider');
    return this.service.complete(request.user.sub, id);
  }
}