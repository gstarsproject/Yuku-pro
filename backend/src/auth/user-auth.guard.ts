import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Request } from 'express';
import { createHash } from 'crypto';
import { AuthService, AuthTokenPayload } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';

type AuthenticatedRequest = Request & { user?: AuthTokenPayload };

@Injectable()
export class UserAuthGuard implements CanActivate {
  constructor(
    private readonly authService: AuthService,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const authorization = request.headers.authorization;
    if (!authorization?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Bearer token diperlukan');
    }

    const token = authorization.slice(7).trim();
    if (!token) throw new UnauthorizedException('Token tidak valid');

    let userId: string;
    let payload: AuthTokenPayload;
    if (/^[a-f0-9]{64}$/i.test(token)) {
      // Preview Worker sessions are opaque 64-character tokens stored only as SHA-256 hashes.
      const tokenHash = createHash('sha256').update(token).digest('hex');
      const session = await this.prisma.userSession.findFirst({
        where: {
          tokenHash,
          expiresAt: { gt: new Date() },
          user: { status: 'ACTIVE', role: { notIn: ['ADMIN', 'SUPERADMIN'] } },
        },
        include: { user: true },
      });
      if (!session || !session.user.email) throw new UnauthorizedException('Sesi tidak valid atau sudah berakhir.');
      userId = session.userId;
      const now = Math.floor(Date.now() / 1000);
      payload = {
        sub: session.user.id,
        email: session.user.email,
        role: session.user.role,
        iat: Math.floor(session.createdAt.getTime() / 1000),
        exp: Math.floor(session.expiresAt.getTime() / 1000),
      };
      if (payload.exp <= now) throw new UnauthorizedException('Sesi sudah berakhir.');
    } else {
      payload = this.authService.verifyAccessToken(token);
      if (payload.role === 'ADMIN' || payload.role === 'SUPERADMIN') {
        throw new UnauthorizedException('Token pengguna diperlukan');
      }
      userId = payload.sub;
    }

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || user.status !== 'ACTIVE' || user.role !== payload.role) {
      throw new UnauthorizedException('Akun tidak aktif');
    }

    request.user = payload;
    return true;
  }
}
