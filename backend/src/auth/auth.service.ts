import {
  Injectable,
  InternalServerErrorException,
  UnauthorizedException,
  ConflictException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, randomBytes, timingSafeEqual, scrypt as scryptCallback } from 'crypto';
import { promisify } from 'util';
import { PrismaService } from '../prisma/prisma.service';

const scrypt = promisify(scryptCallback);
const ACCESS_TOKEN_TTL_SECONDS = 60 * 60 * 8;

type SessionTokenPayload = {
  sub: string;
  email: string;
  role: 'CUSTOMER' | 'PROVIDER' | 'ADMIN';
  iat: number;
  exp: number;
};

type AdminTokenPayload = {
  sub: string;
  email: string;
  role: 'ADMIN';
  iat: number;
  exp: number;
};

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  async register(input: { email: string; password: string; displayName: string; role?: 'CUSTOMER' | 'PROVIDER' }) {
    const email = input.email.trim().toLowerCase();
    const displayName = input.displayName.trim();
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) throw new ConflictException('Email sudah terdaftar');
    const passwordHash = await this.hashPassword(input.password);
    const role = input.role ?? 'CUSTOMER';
    const user = await this.prisma.user.create({
      data: {
        email, passwordHash, role,
        profile: { create: { displayName } },
        ...(role === 'PROVIDER' ? { provider: { create: {} } } : {}),
      },
      include: { profile: true },
    });
    return this.createUserSession(user.id, email, role, user.profile?.displayName ?? displayName);
  }

  async userLogin(emailInput: string, password: string) {
    const email = emailInput.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({ where: { email }, include: { profile: true } });
    if (!user || (user.role !== 'CUSTOMER' && user.role !== 'PROVIDER') || user.status !== 'ACTIVE' || !(await this.verifyPassword(password, user.passwordHash))) {
      throw new UnauthorizedException('Email atau password tidak valid');
    }
    return this.createUserSession(user.id, email, user.role, user.profile?.displayName ?? '');
  }

  private async hashPassword(password: string) {
    const salt = randomBytes(16);
    const derived = (await scrypt(password, salt, 64)) as Buffer;
    return 'scrypt:' + salt.toString('hex') + ':' + derived.toString('hex');
  }

  private createUserSession(userId: string, email: string, role: 'CUSTOMER' | 'PROVIDER', displayName: string) {
    const secret = this.config.get<string>('JWT_ACCESS_SECRET');
    if (!secret || secret.length < 32 || secret === 'replace_with_a_long_random_secret_before_use') {
      throw new InternalServerErrorException('JWT_ACCESS_SECRET belum dikonfigurasi dengan aman');
    }
    const now = Math.floor(Date.now() / 1000);
    const header = this.base64Url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
    const payload: SessionTokenPayload = { sub: userId, email, role, iat: now, exp: now + ACCESS_TOKEN_TTL_SECONDS };
    const body = this.base64Url(JSON.stringify(payload));
    const unsigned = header + '.' + body;
    const signature = createHmac('sha256', secret).update(unsigned).digest('base64url');
    return { accessToken: unsigned + '.' + signature, tokenType: 'Bearer', expiresIn: ACCESS_TOKEN_TTL_SECONDS, user: { id: userId, email, role, displayName } };
  }
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

    const accessToken = this.createAccessToken({
      sub: user.id,
      email: user.email ?? email,
      role: 'ADMIN',
    });

    return {
      accessToken,
      tokenType: 'Bearer',
      expiresIn: ACCESS_TOKEN_TTL_SECONDS,
      user: { id: user.id, email: user.email, role: user.role },
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

  verifyAccessToken(token: string): AdminTokenPayload {
    const secret = this.config.get<string>('JWT_ACCESS_SECRET');
    if (!secret || secret.length < 32) {
      throw new UnauthorizedException('Token tidak valid');
    }

    const parts = token.split('.');
    if (parts.length !== 3) throw new UnauthorizedException('Token tidak valid');

    const [headerPart, payloadPart, signaturePart] = parts;
    let header: { alg?: string; typ?: string };
    let payload: AdminTokenPayload;
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
      payload.role !== 'ADMIN' ||
      typeof payload.exp !== 'number' ||
      payload.exp <= now ||
      typeof payload.iat !== 'number' ||
      payload.iat > now + 60
    ) {
      throw new UnauthorizedException('Token tidak valid atau sudah kedaluwarsa');
    }
    return payload;
  }

  private createAccessToken(
    user: Pick<AdminTokenPayload, 'sub' | 'email' | 'role'>,
  ) {
    const secret = this.config.get<string>('JWT_ACCESS_SECRET');
    if (!secret || secret.length < 32 || secret === 'replace_with_a_long_random_secret_before_use') {
      throw new InternalServerErrorException('JWT_ACCESS_SECRET belum dikonfigurasi dengan aman');
    }

    const now = Math.floor(Date.now() / 1000);
    const header = this.base64Url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
    const payload: AdminTokenPayload = {
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
