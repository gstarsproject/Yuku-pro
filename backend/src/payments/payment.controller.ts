import { Body, Controller, Post, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { AuthTokenPayload } from '../auth/auth.service';
import { UserAuthGuard } from '../auth/user-auth.guard';
import { PaymentService } from './payment.service';

type AuthRequest = Request & { user: AuthTokenPayload };

@Controller('payments')
export class PaymentController {
  constructor(private readonly service: PaymentService) {}

  @UseGuards(UserAuthGuard)
  @Post('checkout')
  checkout(@Req() request: AuthRequest, @Body() body: { bookingId: string }) {
    return this.service.createCheckout(request.user.sub, body.bookingId)
      .then((data) => ({ success: true, data }));
  }

  @Post('webhook/midtrans')
  webhook(@Body() payload: any) {
    return this.service.handleMidtransWebhook(payload);
  }
}
