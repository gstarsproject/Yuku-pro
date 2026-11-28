import { Body, Controller, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { AuthService, AuthTokenPayload } from '../auth/auth.service';
import { UserAuthGuard } from '../auth/user-auth.guard';
import { BookingService } from './booking.service';
import { CreateBookingDto } from './booking.dto';

type AuthRequest = Request & { user: AuthTokenPayload };

@Controller('bookings')
@UseGuards(UserAuthGuard)
export class BookingController {
  constructor(private readonly service: BookingService) {}

  @Get()
  list(@Req() request: AuthRequest) {
    return { success: true, data: this.service.listForUser(request.user.sub) };
  }

  @Get(':id')
  get(@Req() request: AuthRequest, @Param('id') id: string) {
    return this.service.getForUser(request.user.sub, id).then((data) => ({ success: true, data }));
  }

  @Post()
  create(@Req() request: AuthRequest, @Body() dto: CreateBookingDto) {
    return this.service.create(request.user.sub, dto).then((data) => ({ success: true, data }));
  }

  @Post(':id/accept')
  accept(@Req() request: AuthRequest, @Param('id') id: string) {
    return this.service.providerDecision(request.user.sub, id, true).then((data) => ({ success: true, data }));
  }

  @Post(':id/reject')
  reject(@Req() request: AuthRequest, @Param('id') id: string) {
    return this.service.providerDecision(request.user.sub, id, false).then((data) => ({ success: true, data }));
  }

  @Post(':id/start')
  start(@Req() request: AuthRequest, @Param('id') id: string) {
    return this.service.start(request.user.sub, id).then((data) => ({ success: true, data }));
  }

  @Post(':id/complete')
  complete(@Req() request: AuthRequest, @Param('id') id: string) {
    return this.service.complete(request.user.sub, id).then((data) => ({ success: true, data }));
  }

  @Post(':id/confirm')
  confirm(@Req() request: AuthRequest, @Param('id') id: string) {
    return this.service.confirm(request.user.sub, id).then((data) => ({ success: true, data }));
  }
}
