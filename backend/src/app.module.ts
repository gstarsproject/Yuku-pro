import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { HealthModule } from './health/health.module';
import { CategoriesModule } from './categories/categories.module';
import { PrismaModule } from './prisma/prisma.module';
import { BookingModule } from './booking/booking.module';
import { PaymentModule } from './payments/payment.module';
import { AuthModule } from './auth/auth.module';
import { AdminModule } from './admin/admin.module';
import { SocialModule } from './social/social.module';
import { CreatorVerificationModule } from './creator-verification/creator-verification.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    HealthModule,
    CategoriesModule,
    BookingModule,
    PaymentModule,
    AuthModule,
    AdminModule,
    SocialModule,
    CreatorVerificationModule,
  ],
})
export class AppModule {}
