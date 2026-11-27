import { Body, Controller, Post, Param, Req, UseGuards } from '@nestjs/common';
import { TransactionsService } from './transactions.service';
// Replace AuthGuard placeholder with the project's JWT guard and role policies.
@Controller('v1')
export class TransactionsController {
  constructor(private readonly service: TransactionsService) {}

  @Post('bookings')
  create(@Req() req: any, @Body() dto: any) {
    return this.service.createBooking(req.user.id, dto);
  }

  @Post('provider/bookings/:id/respond')
  respond(@Req() req: any, @Param('id') id: string, @Body() body: { accept: boolean }) {
    return this.service.providerRespond(req.user.id, id, body.accept);
  }

  @Post('provider/bookings/:id/submit-completion')
  submitCompletion(@Req() req: any, @Param('id') id: string) {
    return this.service.submitCompletion(req.user.id, id);
  }

  @Post('customer/bookings/:id/confirm-completion')
  confirm(@Req() req: any, @Param('id') id: string) {
    return this.service.customerConfirmCompletion(req.user.id, id);
  }
}
