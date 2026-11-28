import { Body, Controller, Get, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { IsEmail, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { AuthService } from './auth.service';
import { AuthenticatedRequest, UserAuthGuard } from './user-auth.guard';

class AdminLoginDto {
  @IsEmail()
  email!: string;
  @IsString()
  @MinLength(8)
  password!: string;
}

class UserRegisterDto {
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  displayName!: string;
  @IsEmail()
  email!: string;
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password!: string;
}

class UserLoginDto {
  @IsEmail()
  email!: string;
  @IsString()
  @MinLength(8)
  password!: string;
}

class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  displayName?: string;
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  bio?: string;
}

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  login(@Body() body: AdminLoginDto) {
    return this.authService.login(body.email, body.password);
  }

  @Post('register')
  async register(@Body() body: UserRegisterDto) {
    return { success: true, data: await this.authService.registerUser(body.displayName, body.email, body.password) };
  }

  @Post('user/login')
  async userLogin(@Body() body: UserLoginDto) {
    return { success: true, data: await this.authService.loginUser(body.email, body.password) };
  }

  @UseGuards(UserAuthGuard)
  @Get('me')
  async me(@Req() request: AuthenticatedRequest) {
    return { success: true, data: await this.authService.getUserProfile(request.user!.sub) };
  }

  @UseGuards(UserAuthGuard)
  @Post('logout')
  logout() {
    return { success: true, data: { loggedOut: true } };
  }

  @UseGuards(UserAuthGuard)
  @Patch('profile')
  async updateProfile(@Req() request: AuthenticatedRequest, @Body() body: UpdateProfileDto) {
    return { success: true, data: await this.authService.updateUserProfile(request.user!.sub, body) };
  }
}
