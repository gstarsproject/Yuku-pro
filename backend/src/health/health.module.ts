import { Controller, Get, Module } from '@nestjs/common';

@Controller('health')
class HealthController {
  @Get()
  getHealth() {
    return { status: 'ok', service: 'yuku-api', version: '1.0.0' };
  }
}

@Module({ controllers: [HealthController] })
export class HealthModule {}
