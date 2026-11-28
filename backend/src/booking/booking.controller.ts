import { Body, Controller, Param, Post, Req, UseGuards, ForbiddenException, Get, Query, ParseIntPipe, DefaultValuePipe } from '@nestjs/common';
import { Request } from 'express';
import { BookingService } from './booking.service';
import { CreateBookingDto } from './booking.dto';
import { UserAuthGuard, AppUser } from '../auth/user-auth.guard';

type AuthRequest = Request & { user: AppUser };

@Controller('bookings')
@UseGuards(UserAuthGuard)
export class BookingController {
  constructor(private readonly service: BookingService) {}

  @Get()
  listMine(@Req() request: AuthRequest, @Query('limit', new DefaultValuePipe(30), ParseIntPipe) limit: number) {
    if (request.user.role === 'ADMIN') throw new ForbiddenException('Gunakan endpoint admin.');
    return this.service.listMine(request.user.sub, request.user.role, limit);
  }

  @Get(':id')
  getMine(@Req() request: AuthRequest, @Param('id') id: string) {
    if (request.user.role === 'ADMIN') throw new ForbiddenException('Gunakan endpoint admin.');
    return this.service.getMine(request.user.sub, request.user.role, id);
  }

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

  @Post(':id/confirm')
  confirm(@Req() request: AuthRequest, @Param('id') id: string) {
    if (request.user.role !== 'CUSTOMER') throw new ForbiddenException('Aksi khusus customer');
    return this.service.confirmByCustomer(request.user.sub, id);
  }
}