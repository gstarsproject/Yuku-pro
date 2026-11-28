import { Body, Controller, Post } from '@nestjs/common';
import { IsEmail, IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { AuthService } from './auth.service';

class AdminLoginDto {
  @IsEmail() email!: string;
  @IsString() @MinLength(8) password!: string;
}

class UserRegisterDto {
  @IsEmail() email!: string;
  @IsString() @MinLength(8) @MaxLength(128) password!: string;
  @IsString() @MinLength(2) @MaxLength(60) displayName!: string;
  @IsOptional() @IsIn(['CUSTOMER', 'PROVIDER']) role?: 'CUSTOMER' | 'PROVIDER';
}

class UserLoginDto {
  @IsEmail() email!: string;
  @IsString() @MinLength(8) password!: string;
}

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  register(@Body() body: UserRegisterDto) {
    return this.authService.register(body);
  }

  @Post('user/login')
  userLogin(@Body() body: UserLoginDto) {
    return this.authService.userLogin(body.email, body.password);
  }

  @Post('login')
  adminLogin(@Body() body: AdminLoginDto) {
    return this.authService.login(body.email, body.password);
  }
}