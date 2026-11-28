import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { CreatorVerificationController } from './creator-verification.controller';

@Module({ imports: [AuthModule, PrismaModule], controllers: [CreatorVerificationController] })
export class CreatorVerificationModule {}
