import {
  Body,
  Controller,
  ForbiddenException,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Request } from 'express';
import { UserAuthGuard, AppUser } from '../auth/user-auth.guard';
import { PaymentService } from './payment.service';

type AuthRequest = Request & { user: AppUser };

@Controller('payments')
export class PaymentController {
  constructor(private readonly service: PaymentService) {}

  @Post('checkout')
  @UseGuards(UserAuthGuard)
  checkout(@Req() request: AuthRequest, @Body() body: { bookingId: string }) {
    if (request.user.role !== 'CUSTOMER') {
      throw new ForbiddenException('Hanya customer yang dapat melakukan pembayaran.');
    }
    if (!body?.bookingId) {
      throw new ForbiddenException('Booking ID wajib diisi.');
    }
    return this.service.createCheckout(request.user.sub, body.bookingId);
  }

  @Post('webhook/midtrans')
  webhook(@Body() payload: unknown) {
    return this.service.handleMidtransWebhook(payload);
  }
}
