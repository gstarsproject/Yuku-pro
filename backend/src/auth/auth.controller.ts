import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { IsEmail, IsString, MaxLength, MinLength } from 'class-validator';
import { Request } from 'express';
import { AuthService, AuthTokenPayload } from './auth.service';
import { UserAuthGuard } from './user-auth.guard';

class AdminLoginDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(8)
  password!: string;
}

class RegisterCustomerDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(10)
  @MaxLength(128)
  password!: string;

  @IsString()
  @MinLength(2)
  @MaxLength(40)
  displayName!: string;
}

class UserLoginDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(128)
  password!: string;
}

type AuthenticatedRequest = Request & { user: AuthTokenPayload };

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  // Kept for the existing administrator dashboard.
  @Post('login')
  login(@Body() body: AdminLoginDto) {
    return this.authService.login(body.email, body.password);
  }

  @Post('register')
  register(@Body() body: RegisterCustomerDto) {
    return this.authService.registerCustomer(body.email, body.password, body.displayName);
  }

  @Post('user/login')
  loginUser(@Body() body: UserLoginDto) {
    return this.authService.loginUser(body.email, body.password);
  }

  @UseGuards(UserAuthGuard)
  @Get('me')
  me(@Req() request: AuthenticatedRequest) {
    return this.authService.getCurrentUser(request.user.sub);
  }
}
