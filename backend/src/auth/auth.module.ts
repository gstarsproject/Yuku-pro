import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { AdminAuthGuard } from './admin-auth.guard';
import { UserAuthGuard } from './user-auth.guard';

@Module({
  controllers: [AuthController],
  providers: [AuthService, AdminAuthGuard, UserAuthGuard],
  exports: [AuthService, AdminAuthGuard, UserAuthGuard],
})
export class AuthModule {}
