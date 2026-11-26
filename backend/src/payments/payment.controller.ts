import { Body, Controller, Headers, Post, BadRequestException } from '@nestjs/common';
import { PaymentService } from './payment.service';
@Controller('payments')
export class PaymentController {
  constructor(private readonly service: PaymentService) {}
  @Post('checkout')
  checkout(@Headers('x-demo-user-id') userId: string, @Body() body: { bookingId: string }) {
    if (!userId) throw new BadRequestException('JWT authentication required.');
    return this.service.createCheckout(userId, body.bookingId);
  }
  @Post('webhook/midtrans')
  webhook(@Body() payload: any) { return this.service.handleMidtransWebhook(payload); }
}
