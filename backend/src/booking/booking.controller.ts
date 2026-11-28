import { Body, Controller, Get, Param, Post, Req, UseGuards, ForbiddenException } from '@nestjs/common';
import { BookingService } from './booking.service';
import { CreateBookingDto } from './booking.dto';
import { AuthenticatedRequest, UserAuthGuard } from '../auth/user-auth.guard';

@Controller('bookings')
@UseGuards(UserAuthGuard)
export class BookingController {
  constructor(private readonly service: BookingService) {}

  @Get()
  list(@Req() req: AuthenticatedRequest) {
    return this.service.listForUser(req.user!.sub, req.user!.role);
  }

  @Post()
  create(@Req() req: AuthenticatedRequest, @Body() dto: CreateBookingDto) {
    if (req.user!.role !== 'CUSTOMER') throw new ForbiddenException('Hanya akun customer yang dapat membuat booking.');
    return this.service.create(req.user!.sub, dto);
  }

  @Post(':id/accept')
  accept(@Req() req: AuthenticatedRequest, @Param('id') id: string) {
    this.requireProvider(req);
    return this.service.providerDecision(req.user!.sub, id, true);
  }

  @Post(':id/reject')
  reject(@Req() req: AuthenticatedRequest, @Param('id') id: string) {
    this.requireProvider(req);
    return this.service.providerDecision(req.user!.sub, id, false);
  }

  @Post(':id/start')
  start(@Req() req: AuthenticatedRequest, @Param('id') id: string) {
    this.requireProvider(req);
    return this.service.start(req.user!.sub, id);
  }

  @Post(':id/complete')
  complete(@Req() req: AuthenticatedRequest, @Param('id') id: string) {
    this.requireProvider(req);
    return this.service.complete(req.user!.sub, id);
  }

  private requireProvider(req: AuthenticatedRequest) {
    if (req.user!.role !== 'PROVIDER') throw new ForbiddenException('Hanya akun provider yang dapat mengelola booking ini.');
  }
}
