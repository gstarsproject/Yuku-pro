import { Body, Controller, Param, Post, Headers, BadRequestException } from '@nestjs/common';
import { BookingService } from './booking.service';
import { CreateBookingDto } from './booking.dto';
@Controller('bookings')
export class BookingController {
  constructor(private readonly service: BookingService) {}
  // TODO: replace demo header identity with JWT AuthGuard before production.
  @Post() create(@Headers('x-demo-user-id') userId: string, @Body() dto: CreateBookingDto) {
    if (!userId) throw new BadRequestException('Auth belum dipasang: gunakan JWT, bukan header demo.');
    return this.service.create(userId, dto);
  }
  @Post(':id/accept') accept(@Param('id') id: string, @Headers('x-demo-user-id') providerId: string) {
    if (!providerId) throw new BadRequestException('JWT authentication required.');
    return this.service.providerDecision(providerId, id, true);
  }
  @Post(':id/reject') reject(@Param('id') id: string, @Headers('x-demo-user-id') providerId: string) {
    if (!providerId) throw new BadRequestException('JWT authentication required.');
    return this.service.providerDecision(providerId, id, false);
  }
  @Post(':id/start') start(@Param('id') id: string, @Headers('x-demo-user-id') providerId: string) {
    if (!providerId) throw new BadRequestException('JWT authentication required.');
    return this.service.start(providerId, id);
  }
  @Post(':id/complete') complete(@Param('id') id: string, @Headers('x-demo-user-id') providerId: string) {
    if (!providerId) throw new BadRequestException('JWT authentication required.');
    return this.service.complete(providerId, id);
  }
}
