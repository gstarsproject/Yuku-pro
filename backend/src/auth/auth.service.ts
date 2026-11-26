import {
  Injectable,
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, timingSafeEqual, scrypt as scryptCallback } from 'crypto';
import { promisify } from 'util';
import { PrismaService } from '../prisma/prisma.service';

const scrypt = promisify(scryptCallback);
const ACCESS_TOKEN_TTL_SECONDS = 60 * 60 * 8;

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
