import {
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Request } from 'express';
import { AuthTokenPayload } from '../auth/auth.service';
import { UserAuthGuard } from '../auth/user-auth.guard';
import { FollowService } from './follow.service';

type AuthenticatedRequest = Request & { user: AuthTokenPayload };

@Controller('users')
@UseGuards(UserAuthGuard)
export class FollowController {
  constructor(private readonly followService: FollowService) {}

  @Post(':userId/follow')
  follow(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Req() request: AuthenticatedRequest,
  ) {
    return this.followService.follow(request.user.sub, userId);
  }

  @Delete(':userId/follow')
  unfollow(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Req() request: AuthenticatedRequest,
  ) {
    return this.followService.unfollow(request.user.sub, userId);
  }

  @Get(':userId/follow-status')
  status(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Req() request: AuthenticatedRequest,
  ) {
    return this.followService.getFollowStatus(request.user.sub, userId);
  }

  @Get(':userId/followers')
  followers(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.followService.getFollowers(userId);
  }

  @Get(':userId/following')
  following(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.followService.getFollowing(userId);
  }
}
