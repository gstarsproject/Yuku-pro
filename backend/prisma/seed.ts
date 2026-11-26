import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const categories = [
    { name: 'Teman & Companion', slug: 'teman-companion', pillar: 'FRIEND', rateBps: 1000 },
    { name: 'Tour Guide & Experience', slug: 'tour-guide-experience', pillar: 'EXPERIENCE', rateBps: 1200 },
    { name: 'Jasa Profesional', slug: 'jasa-profesional', pillar: 'PRO', rateBps: 800 },
  ];
  for (const item of categories) {
    const category = await prisma.category.upsert({
      where: { slug: item.slug },
      update: { name: item.name, pillar: item.pillar },
      create: { name: item.name, slug: item.slug, pillar: item.pillar },
    });
    await prisma.commissionRule.upsert({
      where: { categoryId: category.id },
      update: { rateBps: item.rateBps, isActive: true },
      create: { categoryId: category.id, rateBps: item.rateBps, isActive: true },
    });
  }
}
main().finally(async () => prisma.$disconnect());
