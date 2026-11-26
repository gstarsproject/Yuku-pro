import {
  ConflictException,
  Injectable,
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, randomBytes, timingSafeEqual, scrypt as scryptCallback } from 'crypto';
import { promisify } from 'util';
import { PrismaService } from '../prisma/prisma.service';

const scrypt = promisify(scryptCallback);
const ACCESS_TOKEN_TTL_SECONDS = 60 * 60 * 8;

export type AuthTokenPayload = {
  sub: string;
  email: string;
  role: 'ADMIN' | 'CUSTOMER' | 'PROVIDER';
  iat: number;
  exp: number;
};

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  // Existing administrator sign-in remains separate from public user sign-in.
  async login(emailInput: string, password: string) {
    const email = emailInput.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({ where: { email } });

    if (
      !user ||
      user.role !== 'ADMIN' ||
      user.status !== 'ACTIVE' ||
      !(await this.verifyPassword(password, user.passwordHash))
    ) {
      throw new UnauthorizedException('Email atau password tidak valid');
    }

    return {
      ...this.createSession(user.id, user.email ?? email, 'ADMIN'),
      user: { id: user.id, email: user.email, role: user.role },
    };
  }

  async registerCustomer(emailInput: string, password: string, displayNameInput: string) {
    const email = emailInput.trim().toLowerCase();
    const displayName = displayNameInput.trim();

    if (displayName.length < 2 || displayName.length > 40) {
      throw new ConflictException('Nama harus terdiri dari 2 sampai 40 karakter');
    }

    const salt = randomBytes(16);
    const derived = (await scrypt(password, salt, 64)) as Buffer;
    const passwordHash = `scrypt:${salt.toString('hex')}:${derived.toString('hex')}`;

    try {
      const user = await this.prisma.user.create({
        data: {
          email,
          passwordHash,
          role: 'CUSTOMER',
          status: 'ACTIVE',
          profile: { create: { displayName } },
        },
        include: { profile: true },
      });
      const session = this.createSession(user.id, user.email ?? email, 'CUSTOMER');
      return {
        ...session,
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          displayName: user.profile?.displayName ?? displayName,
        },
      };
    } catch (error) {
      if (typeof error === 'object' && error !== null && 'code' in error && error.code === 'P2002') {
        throw new ConflictException('Email sudah terdaftar');
      }
      throw error;
    }
  }

  async loginUser(emailInput: string, password: string) {
    const email = emailInput.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({
      where: { email },
      include: { profile: true },
    });

    if (
      !user ||
      user.role === 'ADMIN' ||
      user.status !== 'ACTIVE' ||
      !(await this.verifyPassword(password, user.passwordHash))
    ) {
      throw new UnauthorizedException('Email atau password tidak valid');
    }

    const session = this.createSession(user.id, user.email ?? email, user.role);
    return {
      ...session,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        displayName: user.profile?.displayName ?? null,
      },
    };
  }

  async getCurrentUser(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true },
    });
    if (!user || user.status !== 'ACTIVE' || user.role === 'ADMIN') {
      throw new UnauthorizedException('Akun tidak aktif atau tidak ditemukan');
    }
    return {
      id: user.id,
      email: user.email,
      phone: user.phone,
      role: user.role,
      displayName: user.profile?.displayName ?? null,
      avatarUrl: user.profile?.avatarUrl ?? null,
      bio: user.profile?.bio ?? null,
      city: user.profile?.city ?? null,
      province: user.profile?.province ?? null,
      createdAt: user.createdAt,
    };
  }

  private async verifyPassword(password: string, storedHash: string) {
    const parts = storedHash.split(':');
    if (parts.length !== 3 || parts[0] !== 'scrypt') return false;

    const [, saltHex, hashHex] = parts;
    if (!/^[a-f0-9]{32}$/i.test(saltHex) || !/^[a-f0-9]{128}$/i.test(hashHex)) {
      return false;
    }

    const expected = Buffer.from(hashHex, 'hex');
    const actual = (await scrypt(password, Buffer.from(saltHex, 'hex'), 64)) as Buffer;
    return actual.length === expected.length && timingSafeEqual(actual, expected);
  }

  verifyAccessToken(token: string): AuthTokenPayload {
    const secret = this.config.get<string>('JWT_ACCESS_SECRET');
    if (!secret || secret.length < 32) {
      throw new UnauthorizedException('Token tidak valid');
    }

    const parts = token.split('.');
    if (parts.length !== 3) throw new UnauthorizedException('Token tidak valid');

    const [headerPart, payloadPart, signaturePart] = parts;
    let header: { alg?: string; typ?: string };
    let payload: AuthTokenPayload;
    try {
      header = JSON.parse(Buffer.from(headerPart, 'base64url').toString('utf8'));
      payload = JSON.parse(Buffer.from(payloadPart, 'base64url').toString('utf8'));
    } catch {
      throw new UnauthorizedException('Token tidak valid');
    }

    if (header.alg !== 'HS256' || header.typ !== 'JWT') {
      throw new UnauthorizedException('Token tidak valid');
    }

    const unsigned = headerPart + '.' + payloadPart;
    const expected = createHmac('sha256', secret).update(unsigned).digest();
    let actual: Buffer;
    try {
      actual = Buffer.from(signaturePart, 'base64url');
    } catch {
      throw new UnauthorizedException('Token tidak valid');
    }
    if (actual.length !== expected.length || !timingSafeEqual(actual, expected)) {
      throw new UnauthorizedException('Token tidak valid');
    }

    const now = Math.floor(Date.now() / 1000);
    if (
      !payload ||
      typeof payload.sub !== 'string' ||
      typeof payload.email !== 'string' ||
      !['ADMIN', 'CUSTOMER', 'PROVIDER'].includes(payload.role) ||
      typeof payload.exp !== 'number' ||
      payload.exp <= now ||
      typeof payload.iat !== 'number' ||
      payload.iat > now + 60
    ) {
      throw new UnauthorizedException('Token tidak valid atau sudah kedaluwarsa');
    }
    return payload;
  }

  private createSession(userId: string, email: string, role: AuthTokenPayload['role']) {
    const accessToken = this.createAccessToken({ sub: userId, email, role });
    return {
      accessToken,
      tokenType: 'Bearer',
      expiresIn: ACCESS_TOKEN_TTL_SECONDS,
    };
  }

  private createAccessToken(
    user: Pick<AuthTokenPayload, 'sub' | 'email' | 'role'>,
  ) {
    const secret = this.config.get<string>('JWT_ACCESS_SECRET');
    if (!secret || secret.length < 32 || secret === 'replace_with_a_long_random_secret_before_use') {
      throw new InternalServerErrorException('JWT_ACCESS_SECRET belum dikonfigurasi dengan aman');
    }

    const now = Math.floor(Date.now() / 1000);
    const header = this.base64Url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
    const payload: AuthTokenPayload = {
      ...user,
      iat: now,
      exp: now + ACCESS_TOKEN_TTL_SECONDS,
    };
    const body = this.base64Url(JSON.stringify(payload));
    const unsigned = header + '.' + body;
    const signature = createHmac('sha256', secret).update(unsigned).digest('base64url');
    return unsigned + '.' + signature;
  }

  private base64Url(value: string) {
    return Buffer.from(value).toString('base64url');
  }
}
