import { Body, Controller, Delete, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { AuthenticatedRequest, UserAuthGuard } from '../auth/user-auth.guard';
import { SocialService } from './social.service';

class CreatePostDto {
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  content!: string;
  @IsOptional()
  @IsIn(['PUBLIC', 'FOLLOWERS', 'PRIVATE'])
  audience?: 'PUBLIC' | 'FOLLOWERS' | 'PRIVATE';
}

class CreateCommentDto {
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  content!: string;
}

@Controller()
@UseGuards(UserAuthGuard)
export class SocialController {
  constructor(private readonly social: SocialService) {}

  @Get('posts')
  async posts(@Req() req: AuthenticatedRequest, @Query('following') following?: string) {
    return { success: true, data: await this.social.listPosts(req.user!.sub, following === 'true') };
  }

  @Post('posts')
  async createPost(@Req() req: AuthenticatedRequest, @Body() body: CreatePostDto) {
    return { success: true, data: await this.social.createPost(req.user!.sub, body) };
  }

  @Post('posts/:id/like')
  async like(@Req() req: AuthenticatedRequest, @Param('id') id: string) {
    return { success: true, data: await this.social.likePost(req.user!.sub, id) };
  }

  @Delete('posts/:id/like')
  async unlike(@Req() req: AuthenticatedRequest, @Param('id') id: string) {
    return { success: true, data: await this.social.unlikePost(req.user!.sub, id) };
  }

  @Get('posts/:id/comments')
  async comments(@Param('id') id: string) {
    return { success: true, data: await this.social.listComments(id) };
  }

  @Post('posts/:id/comments')
  async comment(@Req() req: AuthenticatedRequest, @Param('id') id: string, @Body() body: CreateCommentDto) {
    return { success: true, data: await this.social.createComment(req.user!.sub, id, body.content) };
  }

  @Get('users/search')
  async search(@Req() req: AuthenticatedRequest, @Query('q') q = '') {
    return { success: true, data: await this.social.searchUsers(req.user!.sub, q) };
  }

  @Get('users/:id/profile')
  async profile(@Req() req: AuthenticatedRequest, @Param('id') id: string) {
    return { success: true, data: await this.social.profile(req.user!.sub, id) };
  }

  @Post('users/:id/follow')
  async follow(@Req() req: AuthenticatedRequest, @Param('id') id: string) {
    return { success: true, data: await this.social.follow(req.user!.sub, id) };
  }

  @Delete('users/:id/follow')
  async unfollow(@Req() req: AuthenticatedRequest, @Param('id') id: string) {
    return { success: true, data: await this.social.unfollow(req.user!.sub, id) };
  }

  @Get('stories')
  async stories(@Req() req: AuthenticatedRequest) {
    return { success: true, data: await this.social.listStories(req.user!.sub) };
  }
}
