import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAvailabilityDto, CreateProviderServiceDto, UpdateProviderServiceDto } from './provider.dto';

@Injectable()
export class ProviderService {
  constructor(private readonly prisma: PrismaService) {}

  private async profile(userId: string) {
    const profile = await this.prisma.providerProfile.findUnique({ where: { userId } });
    if (!profile) throw new NotFoundException('Profil provider belum dibuat.');
    return profile;
  }

  async listServices(userId: string) {
    const profile = await this.profile(userId);
    return this.prisma.service.findMany({
      where: { providerId: profile.id },
      orderBy: { updatedAt: 'desc' },
      include: { category: { select: { id: true, name: true, slug: true, pillar: true } } },
    });
  }

  async createService(userId: string, dto: CreateProviderServiceDto) {
    const profile = await this.profile(userId);
    const category = await this.prisma.category.findFirst({ where: { id: dto.categoryId, isActive: true } });
    if (!category) throw new NotFoundException('Kategori tidak ditemukan atau tidak aktif.');
    if (dto.currency && !/^[A-Z]{3}$/.test(dto.currency)) throw new BadRequestException('Kode mata uang harus 3 huruf kapital.');
    return this.prisma.service.create({
      data: {
        providerId: profile.id,
        categoryId: category.id,
        title: dto.title.trim(),
        description: dto.description.trim(),
        mode: dto.mode,
        priceAmount: dto.priceAmount,
        currency: dto.currency ?? 'IDR',
        priceUnit: dto.priceUnit,
        durationMinutes: dto.durationMinutes,
        city: dto.city?.trim(),
        province: dto.province?.trim(),
        isPublished: false,
      },
      include: { category: true },
    });
  }

  async updateService(userId: string, serviceId: string, dto: UpdateProviderServiceDto) {
    const profile = await this.profile(userId);
    const service = await this.prisma.service.findFirst({ where: { id: serviceId, providerId: profile.id } });
    if (!service) throw new NotFoundException('Layanan tidak ditemukan.');
    if (dto.currency && !/^[A-Z]{3}$/.test(dto.currency)) throw new BadRequestException('Kode mata uang harus 3 huruf kapital.');
    if (dto.isPublished === true && profile.verificationStatus !== 'VERIFIED') {
      throw new BadRequestException('Provider harus terverifikasi sebelum layanan dipublikasikan.');
    }
    const { isPublished, ...details } = dto;
    return this.prisma.service.update({
      where: { id: service.id },
      data: {
        ...details,
        ...(details.title ? { title: details.title.trim() } : {}),
        ...(details.description ? { description: details.description.trim() } : {}),
        ...(details.city ? { city: details.city.trim() } : {}),
        ...(details.province ? { province: details.province.trim() } : {}),
        ...(isPublished !== undefined ? { isPublished } : {}),
      },
      include: { category: true },
    });
  }

  async listAvailability(userId: string) {
    const profile = await this.profile(userId);
    return this.prisma.availability.findMany({
      where: { providerId: profile.id },
      orderBy: { startsAt: 'asc' },
      take: 200,
    });
  }

  async createAvailability(userId: string, dto: CreateAvailabilityDto) {
    const profile = await this.profile(userId);
    const startsAt = new Date(dto.startsAt);
    const endsAt = new Date(dto.endsAt);
    if (Number.isNaN(startsAt.getTime()) || Number.isNaN(endsAt.getTime()) || startsAt <= new Date() || endsAt <= startsAt) {
      throw new BadRequestException('Jadwal harus valid dan berada di masa depan.');
    }
    const overlap = await this.prisma.availability.findFirst({
      where: { providerId: profile.id, startsAt: { lt: endsAt }, endsAt: { gt: startsAt } },
    });
    if (overlap) throw new ConflictException('Jadwal bertabrakan dengan jadwal yang sudah ada.');
    return this.prisma.availability.create({
      data: { providerId: profile.id, startsAt, endsAt, isBlocked: dto.isBlocked ?? false },
    });
  }

  async deleteAvailability(userId: string, availabilityId: string) {
    const profile = await this.profile(userId);
    const result = await this.prisma.availability.deleteMany({ where: { id: availabilityId, providerId: profile.id } });
    if (result.count !== 1) throw new NotFoundException('Jadwal tidak ditemukan.');
    return { success: true };
  }
}
