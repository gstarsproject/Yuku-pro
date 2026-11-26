import { Controller, Get, Module } from '@nestjs/common';

const categories = [
  { id: 'friend', name: 'Friend', slug: 'friend', description: 'Jasa pertemanan untuk aktivitas sosial yang aman.' },
  { id: 'experience', name: 'Experience', slug: 'experience', description: 'Pengalaman, aktivitas, dan pemandu lokal.' },
  { id: 'pro', name: 'Professional', slug: 'professional', description: 'Layanan dari penyedia jasa profesional.' },
];

@Controller('categories')
class CategoriesController {
  @Get()
  list() {
    return { items: categories };
  }
}

@Module({ controllers: [CategoriesController] })
export class CategoriesModule {}
