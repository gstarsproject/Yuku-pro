import { Body, Controller, Delete, ForbiddenException, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { AppUser, UserAuthGuard } from '../auth/user-auth.guard';
import { CreateAvailabilityDto, CreateProviderServiceDto, UpdateProviderServiceDto } from './provider.dto';
import { ProviderService } from './provider.service';

type AuthRequest = Request & { user: AppUser };

@Controller('provider/me')
@UseGuards(UserAuthGuard)
export class ProviderController {
  constructor(private readonly service: ProviderService) {}

  private assertProvider(request: AuthRequest) {
    if (request.user.role !== 'PROVIDER') throw new ForbiddenException('Fitur ini khusus provider.');
  }

  @Get('services')
  listServices(@Req() request: AuthRequest) {
    this.assertProvider(request);
    return this.service.listServices(request.user.sub);
  }

  @Post('services')
  createService(@Req() request: AuthRequest, @Body() dto: CreateProviderServiceDto) {
    this.assertProvider(request);
    return this.service.createService(request.user.sub, dto);
  }

  @Patch('services/:id')
  updateService(@Req() request: AuthRequest, @Param('id') id: string, @Body() dto: UpdateProviderServiceDto) {
    this.assertProvider(request);
    return this.service.updateService(request.user.sub, id, dto);
  }

  @Get('availability')
  listAvailability(@Req() request: AuthRequest) {
    this.assertProvider(request);
    return this.service.listAvailability(request.user.sub);
  }

  @Post('availability')
  createAvailability(@Req() request: AuthRequest, @Body() dto: CreateAvailabilityDto) {
    this.assertProvider(request);
    return this.service.createAvailability(request.user.sub, dto);
  }

  @Delete('availability/:id')
  deleteAvailability(@Req() request: AuthRequest, @Param('id') id: string) {
    this.assertProvider(request);
    return this.service.deleteAvailability(request.user.sub, id);
  }
}
