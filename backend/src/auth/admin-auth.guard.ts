import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Request } from 'express';
import { AuthService } from './auth.service';

type AdminRequest = Request & {
  user?: { sub: string; email: string; role: 'ADMIN'; iat: number; exp: number };
};

@Injectable()
export class AdminAuthGuard implements CanActivate {
  constructor(private readonly authService: AuthService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<AdminRequest>();
    const authorization = request.headers.authorization;

    if (!authorization?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Bearer token diperlukan');
    }

    const token = authorization.slice(7).trim();
    if (!token) throw new UnauthorizedException('Token tidak valid');

    request.user = this.authService.verifyAccessToken(token);
    return true;
  }
}
