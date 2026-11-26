import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Request } from 'express';
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

    const payload = this.authService.verifyAccessToken(token);
    if (payload.role === 'ADMIN') {
      throw new UnauthorizedException('Token pengguna diperlukan');
    }

    const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user || user.status !== 'ACTIVE' || user.role !== payload.role) {
      throw new UnauthorizedException('Akun tidak aktif');
    }

    request.user = payload;
    return true;
  }
}
