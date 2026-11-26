import { Module } from '@nestjs/common';

@Module({})
export class AuthModule {}import {
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { createHmac, scryptSync, timingSafeEqual } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService) {}

  private verifyPassword(password: string, stored: string): boolean {
    const parts = stored.split(':');

    if (parts.length !== 3 || parts[0] !== 'scrypt') {
      return false;
    }

    try {
      const salt = Buffer.from(parts[1], 'hex');
      const expected = Buffer.from(parts[2], 'hex');
      const actual = scryptSync(password, salt, expected.length);

      return actual.length === expected.length &&
        timingSafeEqual(actual, expected);
    } catch {
      return false;
    }
  }

  private createToken(user: { id: string; email: string }) {
    const secret = process.env.JWT_ACCESS_SECRET;

    if (!secret || secret.length < 32) {
      throw new Error('JWT_ACCESS_SECRET belum dikonfigurasi dengan aman');
    }

    const now = Math.floor(Date.now() / 1000);
    const header = Buffer.from(
      JSON.stringify({ alg: 'HS256', typ: 'JWT' }),
    ).toString('base64url');

    const payload = Buffer.from(
      JSON.stringify({
        sub: user.id,
        email: user.email,
        role: 'ADMIN',
        iat: now,
        exp: now + 8 * 60 * 60,
      }),
    ).toString('base64url');

    const data = `${header}.${payload}`;
    const signature = createHmac('sha256', secret)
      .update(data)
      .digest('base64url');

    return `${data}.${signature}`;
  }

  async login(email: string, password: string) {
    const user = await this.prisma.user.findUnique({
      where: { email: email.trim().toLowerCase() },
    });

    if (
      !user ||
      user.role !== 'ADMIN' ||
      user.status !== 'ACTIVE' ||
      !this.verifyPassword(password, user.passwordHash)
    ) {
      throw new UnauthorizedException('Email atau password salah');
    }

    return {
      accessToken: this.createToken({
        id: user.id,
        email: user.email!,
      }),
      tokenType: 'Bearer',
      expiresIn: 28800,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
      },
    };
  }
        }
