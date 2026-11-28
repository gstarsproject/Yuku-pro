import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminCreatorVerificationController } from './creator-verification.controller';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [AuthModule],
  controllers: [AdminController, AdminCreatorVerificationController],
})
export class AdminModule {}
