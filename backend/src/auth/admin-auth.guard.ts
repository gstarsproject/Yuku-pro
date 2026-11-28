import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Request } from 'express';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';

type AdminRequest = Request & {
  user?: { sub: string; email: string; role: 'ADMIN'; iat: number; exp: number };
};

@Injectable()
export class AdminAuthGuard implements CanActivate {
  constructor(
    private readonly authService: AuthService,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AdminRequest>();
    const authorization = request.headers.authorization;

    if (!authorization?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Bearer token diperlukan');
    }

    const token = authorization.slice(7).trim();
    if (!token) throw new UnauthorizedException('Token tidak valid');

    const payload = this.authService.verifyAccessToken(token);
    if (payload.role !== 'ADMIN') throw new UnauthorizedException('Akses khusus admin');
    const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user || user.role !== 'ADMIN' || user.status !== 'ACTIVE') {
      throw new UnauthorizedException('Akun admin tidak aktif');
    }
    request.user = { ...payload, role: 'ADMIN' };
    return true;
  }
}
