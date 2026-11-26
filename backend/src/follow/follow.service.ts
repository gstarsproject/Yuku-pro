import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class FollowService {
  constructor(private readonly prisma: PrismaService) {}

  private async ensureFollowableUser(userId: string) {
    const user = await this.prisma.user.findFirst({
      where: { id: userId, status: 'ACTIVE', role: { in: ['CUSTOMER', 'PROVIDER'] } },
      select: { id: true },
    });
    if (!user) throw new NotFoundException('Pengguna tidak ditemukan');
    return user;
  }

  async follow(followerId: string, followingId: string) {
    if (followerId === followingId) {
      throw new BadRequestException('Kamu tidak bisa mengikuti akun sendiri');
    }
    await this.ensureFollowableUser(followingId);

    try {
      await this.prisma.follow.create({ data: { followerId, followingId } });
    } catch (error) {
      // Repeating the same request is safe and does not create duplicate follows.
      if (!(typeof error === 'object' && error !== null && 'code' in error && error.code === 'P2002')) {
        throw error;
      }
    }
    return { following: true };
  }

  async unfollow(followerId: string, followingId: string) {
    await this.prisma.follow.deleteMany({ where: { followerId, followingId } });
    return { following: false };
  }

  async getFollowStatus(viewerId: string, targetId: string) {
    await this.ensureFollowableUser(targetId);
    const [following, followersCount, followingCount] = await Promise.all([
      this.prisma.follow.findUnique({
        where: { followerId_followingId: { followerId: viewerId, followingId: targetId } },
        select: { id: true },
      }),
      this.prisma.follow.count({ where: { followingId: targetId } }),
      this.prisma.follow.count({ where: { followerId: targetId } }),
    ]);
    return {
      following: Boolean(following),
      followersCount,
      followingCount,
    };
  }

  async getFollowers(userId: string) {
    await this.ensureFollowableUser(userId);
    const [total, rows] = await Promise.all([
      this.prisma.follow.count({ where: { followingId: userId } }),
      this.prisma.follow.findMany({
        where: { followingId: userId },
        orderBy: { createdAt: 'desc' },
        take: 50,
        select: {
          createdAt: true,
          follower: {
            select: {
              id: true,
              profile: { select: { displayName: true, avatarUrl: true } },
            },
          },
        },
      }),
    ]);
    return {
      total,
      items: rows.map((row) => ({
        id: row.follower.id,
        displayName: row.follower.profile?.displayName ?? 'Pengguna MAVO',
        avatarUrl: row.follower.profile?.avatarUrl ?? null,
        followedAt: row.createdAt,
      })),
    };
  }

  async getFollowing(userId: string) {
    await this.ensureFollowableUser(userId);
    const [total, rows] = await Promise.all([
      this.prisma.follow.count({ where: { followerId: userId } }),
      this.prisma.follow.findMany({
        where: { followerId: userId },
        orderBy: { createdAt: 'desc' },
        take: 50,
        select: {
          createdAt: true,
          following: {
            select: {
              id: true,
              profile: { select: { displayName: true, avatarUrl: true } },
            },
          },
        },
      }),
    ]);
    return {
      total,
      items: rows.map((row) => ({
        id: row.following.id,
        displayName: row.following.profile?.displayName ?? 'Pengguna MAVO',
        avatarUrl: row.following.profile?.avatarUrl ?? null,
        followedAt: row.createdAt,
      })),
    };
  }
}
