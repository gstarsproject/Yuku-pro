import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { Request } from 'express';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';

export type AuthenticatedUser = {
  sub: string;
  email: string;
  role: 'CUSTOMER' | 'PROVIDER';
  iat: number;
  exp: number;
};

export type AuthenticatedRequest = Request & { user?: AuthenticatedUser };

@Injectable()
export class UserAuthGuard implements CanActivate {
  constructor(private readonly authService: AuthService, private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const authorization = request.headers.authorization;
    if (!authorization?.startsWith('Bearer ')) throw new UnauthorizedException('Bearer token diperlukan.');
    const payload = this.authService.verifyUserAccessToken(authorization.slice(7).trim());
    const user = await this.prisma.user.findFirst({
      where: { id: payload.sub, status: 'ACTIVE', role: { in: ['CUSTOMER', 'PROVIDER'] } },
      select: { id: true },
    });
    if (!user) throw new UnauthorizedException('Akun tidak aktif atau tidak ditemukan.');
    request.user = payload as AuthenticatedUser;
    return true;
  }
}
