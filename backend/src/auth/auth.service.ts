import {
  Injectable,
  InternalServerErrorException,
  UnauthorizedException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, randomBytes, timingSafeEqual, scrypt as scryptCallback } from 'crypto';
import { promisify } from 'util';
import { PrismaService } from '../prisma/prisma.service';

const scrypt = promisify(scryptCallback);
const ACCESS_TOKEN_TTL_SECONDS = 60 * 60 * 8;

type TokenRole = 'ADMIN' | 'CUSTOMER' | 'PROVIDER';
type TokenPayload = {
  sub: string;
  email: string;
  role: TokenRole;
  iat: number;
  exp: number;
};

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  async login(emailInput: string, password: string) {
    const email = emailInput.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user || user.role !== 'ADMIN' || user.status !== 'ACTIVE' ||
        !(await this.verifyPassword(password, user.passwordHash))) {
      throw new UnauthorizedException('Email atau password tidak valid');
    }
    const accessToken = this.createAccessToken({ sub: user.id, email: user.email ?? email, role: 'ADMIN' });
    return {
      accessToken, tokenType: 'Bearer', expiresIn: ACCESS_TOKEN_TTL_SECONDS,
      user: { id: user.id, email: user.email, role: user.role },
    };
  }

  async registerUser(displayNameInput: string, emailInput: string, password: string) {
    const displayName = displayNameInput.trim();
    const email = emailInput.trim().toLowerCase();
    if (displayName.length < 2 || displayName.length > 80) {
      throw new BadRequestException('Nama harus berisi 2 sampai 80 karakter.');
    }
    if (password.length < 8 || password.length > 128) {
      throw new BadRequestException('Password harus berisi 8 sampai 128 karakter.');
    }
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) throw new ConflictException('Email sudah terdaftar.');
    const salt = randomBytes(16);
    const hash = (await scrypt(password, salt, 64)) as Buffer;
    const passwordHash = 'scrypt:' + salt.toString('hex') + ':' + hash.toString('hex');
    const user = await this.prisma.user.create({
      data: {
        email,
        passwordHash,
        role: 'CUSTOMER',
        profile: { create: { displayName } },
      },
      include: { profile: true },
    });
    const accessToken = this.createAccessToken({ sub: user.id, email, role: 'CUSTOMER' });
    return {
      accessToken, tokenType: 'Bearer', expiresIn: ACCESS_TOKEN_TTL_SECONDS,
      user: { id: user.id, email: user.email, role: user.role, displayName: user.profile?.displayName },
    };
  }

  async loginUser(emailInput: string, password: string) {
    const email = emailInput.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({ where: { email }, include: { profile: true } });
    if (!user || !['CUSTOMER', 'PROVIDER'].includes(user.role) || user.status !== 'ACTIVE' ||
        !(await this.verifyPassword(password, user.passwordHash))) {
      throw new UnauthorizedException('Email atau password tidak valid');
    }
    const accessToken = this.createAccessToken({
      sub: user.id, email: user.email ?? email, role: user.role as 'CUSTOMER' | 'PROVIDER',
    });
    return {
      accessToken, tokenType: 'Bearer', expiresIn: ACCESS_TOKEN_TTL_SECONDS,
      user: { id: user.id, email: user.email, role: user.role, displayName: user.profile?.displayName },
    };
  }

  async getUserProfile(userId: string) {
    const user = await this.prisma.user.findFirst({
      where: { id: userId, status: 'ACTIVE' },
      include: { profile: true },
    });
    if (!user) throw new UnauthorizedException('Akun tidak ditemukan atau tidak aktif.');
    return {
      id: user.id, email: user.email, role: user.role,
      displayName: user.profile?.displayName ?? '',
      avatarUrl: user.profile?.avatarUrl ?? null,
      bio: user.profile?.bio ?? '',
      city: user.profile?.city ?? null,
      province: user.profile?.province ?? null,
    };
  }

  async updateUserProfile(userId: string, input: { displayName?: string; bio?: string }) {
    const data: { displayName?: string; bio?: string } = {};
    if (input.displayName !== undefined) {
      const name = input.displayName.trim();
      if (name.length < 2 || name.length > 80) throw new BadRequestException('Nama harus 2 sampai 80 karakter.');
      data.displayName = name;
    }
    if (input.bio !== undefined) {
      const bio = input.bio.trim();
      if (bio.length > 1000) throw new BadRequestException('Bio maksimal 1000 karakter.');
      data.bio = bio;
    }
    await this.prisma.profile.upsert({
      where: { userId },
      create: { userId, displayName: data.displayName ?? 'MAVO User', bio: data.bio },
      update: data,
    });
    return this.getUserProfile(userId);
  }

  private async verifyPassword(password: string, storedHash: string) {
    const parts = storedHash.split(':');
    if (parts.length !== 3 || parts[0] !== 'scrypt') return false;
    const [, saltHex, hashHex] = parts;
    if (!/^[a-f0-9]{32}$/i.test(saltHex) || !/^[a-f0-9]{128}$/i.test(hashHex)) return false;
    const expected = Buffer.from(hashHex, 'hex');
    const actual = (await scrypt(password, Buffer.from(saltHex, 'hex'), 64)) as Buffer;
    return actual.length === expected.length && timingSafeEqual(actual, expected);
  }

  verifyAccessToken(token: string): TokenPayload {
    const payload = this.verifyToken(token);
    if (payload.role !== 'ADMIN') throw new UnauthorizedException('Token admin diperlukan.');
    return payload;
  }

  verifyUserAccessToken(token: string): TokenPayload {
    const payload = this.verifyToken(token);
    if (payload.role === 'ADMIN') throw new UnauthorizedException('Token pengguna diperlukan.');
    return payload;
  }

  private verifyToken(token: string): TokenPayload {
    const secret = this.config.get<string>('JWT_ACCESS_SECRET');
    if (!secret || secret.length < 32) throw new UnauthorizedException('Token tidak valid');
    const parts = token.split('.');
    if (parts.length !== 3) throw new UnauthorizedException('Token tidak valid');
    const [headerPart, payloadPart, signaturePart] = parts;
    let header: { alg?: string; typ?: string };
    let payload: TokenPayload;
    try {
      header = JSON.parse(Buffer.from(headerPart, 'base64url').toString('utf8'));
      payload = JSON.parse(Buffer.from(payloadPart, 'base64url').toString('utf8'));
    } catch {
      throw new UnauthorizedException('Token tidak valid');
    }
    if (header.alg !== 'HS256' || header.typ !== 'JWT') throw new UnauthorizedException('Token tidak valid');
    const unsigned = headerPart + '.' + payloadPart;
    const expected = createHmac('sha256', secret).update(unsigned).digest();
    const actual = Buffer.from(signaturePart, 'base64url');
    if (actual.length !== expected.length || !timingSafeEqual(actual, expected)) {
      throw new UnauthorizedException('Token tidak valid');
    }
    const now = Math.floor(Date.now() / 1000);
    if (!payload || typeof payload.sub !== 'string' || typeof payload.email !== 'string' ||
        !['ADMIN', 'CUSTOMER', 'PROVIDER'].includes(payload.role) ||
        typeof payload.exp !== 'number' || payload.exp <= now ||
        typeof payload.iat !== 'number' || payload.iat > now + 60) {
      throw new UnauthorizedException('Token tidak valid atau sudah kedaluwarsa');
    }
    return payload;
  }

  private createAccessToken(user: Pick<TokenPayload, 'sub' | 'email' | 'role'>) {
    const secret = this.config.get<string>('JWT_ACCESS_SECRET');
    if (!secret || secret.length < 32 || secret === 'replace_with_a_long_random_secret_before_use') {
      throw new InternalServerErrorException('JWT_ACCESS_SECRET belum dikonfigurasi dengan aman');
    }
    const now = Math.floor(Date.now() / 1000);
    const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
    const payload: TokenPayload = { ...user, iat: now, exp: now + ACCESS_TOKEN_TTL_SECONDS };
    const body = Buffer.from(JSON.stringify(payload)).toString('base64url');
    const unsigned = header + '.' + body;
    const signature = createHmac('sha256', secret).update(unsigned).digest('base64url');
    return unsigned + '.' + signature;
  }
}
