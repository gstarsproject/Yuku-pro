import { PrismaClient, UserRole, UserStatus } from '@prisma/client';
import { randomBytes, scrypt as scryptCallback } from 'crypto';
import { promisify } from 'util';

const prisma = new PrismaClient();
const scrypt = promisify(scryptCallback);

async function main() {
  const email = process.env.ADMIN_BOOTSTRAP_EMAIL?.trim().toLowerCase();
  const password = process.env.ADMIN_BOOTSTRAP_PASSWORD;

  if (!email || !password) {
    throw new Error('Set ADMIN_BOOTSTRAP_EMAIL and ADMIN_BOOTSTRAP_PASSWORD in the backend host environment.');
  }
  if (password.length < 12 || password.startsWith('replace_with_')) {
    throw new Error('ADMIN_BOOTSTRAP_PASSWORD must be at least 12 characters.');
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new Error('ADMIN_BOOTSTRAP_EMAIL is not a valid email address.');
  }

  const adminCount = await prisma.user.count({ where: { role: UserRole.ADMIN } });
  if (adminCount > 0) {
    throw new Error('An ADMIN account already exists. Bootstrap is one-time and will not create or change accounts.');
  }

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    throw new Error('This email already belongs to an account. Bootstrap will not change an existing account.');
  }

  const salt = randomBytes(16);
  const derived = (await scrypt(password, salt, 64)) as Buffer;
  const passwordHash = `scrypt:${salt.toString('hex')}:${derived.toString('hex')}`;

  await prisma.user.create({
    data: {
      email,
      passwordHash,
      role: UserRole.ADMIN,
      status: UserStatus.ACTIVE,
    },
  });

  console.log(`Initial ADMIN account created for ${email}. Remove ADMIN_BOOTSTRAP_EMAIL and ADMIN_BOOTSTRAP_PASSWORD from the host environment now.`);
}

main()
  .catch((error) => {
    console.error(error instanceof Error ? error.message : 'Admin bootstrap failed');
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
