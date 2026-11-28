import { Body, Controller, ForbiddenException, Post, Req, UseGuards } from '@nestjs/common';
import { PaymentService } from './payment.service';
import { AuthenticatedRequest, UserAuthGuard } from '../auth/user-auth.guard';

@Controller('payments')
export class PaymentController {
  constructor(private readonly service: PaymentService) {}

  @UseGuards(UserAuthGuard)
  @Post('checkout')
  checkout(@Req() req: AuthenticatedRequest, @Body() body: { bookingId: string }) {
    if (req.user!.role !== 'CUSTOMER') throw new ForbiddenException('Hanya customer yang dapat membayar booking.');
    return this.service.createCheckout(req.user!.sub, body.bookingId);
  }

  // Public endpoint: Midtrans authenticates events using its signature_key in the service.
  @Post('webhook/midtrans')
  webhook(@Body() payload: any) {
    return this.service.handleMidtransWebhook(payload);
  }
}
