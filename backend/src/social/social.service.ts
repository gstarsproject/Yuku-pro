import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SocialService {
  constructor(private readonly prisma: PrismaService) {}

  async listPosts(userId: string, followingOnly = false) {
    const follows = followingOnly
      ? await this.prisma.socialFollow.findMany({ where: { followerId: userId }, select: { followingId: true } })
      : [];
    const followedIds = follows.map((item) => item.followingId);
    const rows = await this.prisma.socialPost.findMany({
      where: {
        AND: [
          followingOnly ? { authorId: { in: followedIds } } : {},
          {
            OR: [
              { audience: 'PUBLIC' },
              { authorId: userId },
              { audience: 'FOLLOWERS', author: { socialFollowers: { some: { followerId: userId } } } },
            ],
          },
        ],
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
      include: {
        author: { include: { profile: true } },
        media: { orderBy: { position: 'asc' } },
        _count: { select: { likes: true, comments: true } },
        likes: { where: { userId }, select: { id: true }, take: 1 },
      },
    });
    return rows.map((post) => ({
      id: post.id,
      authorId: post.authorId,
      authorName: post.author.profile?.displayName ?? 'Pengguna MAVO',
      authorAvatar: post.author.profile?.avatarUrl ?? null,
      content: post.content,
      audience: post.audience,
      createdAt: post.createdAt,
      likesCount: post._count.likes,
      commentsCount: post._count.comments,
      likedByMe: post.likes.length > 0,
      media: post.media,
    }));
  }

  async createPost(userId: string, input: { content: string; audience?: 'PUBLIC' | 'FOLLOWERS' | 'PRIVATE' }) {
    const content = input.content?.trim() ?? '';
    if (!content || content.length > 2000) throw new BadRequestException('Isi postingan wajib diisi (maksimal 2000 karakter).');
    const post = await this.prisma.socialPost.create({
      data: { authorId: userId, content, audience: input.audience ?? 'PUBLIC' },
      include: { author: { include: { profile: true } }, _count: { select: { likes: true, comments: true } } },
    });
    return {
      id: post.id, authorId: post.authorId,
      authorName: post.author.profile?.displayName ?? 'Pengguna MAVO',
      content: post.content, audience: post.audience, createdAt: post.createdAt,
      likesCount: post._count.likes, commentsCount: post._count.comments, likedByMe: false, media: [],
    };
  }

  async likePost(userId: string, postId: string) {
    const post = await this.prisma.socialPost.findUnique({ where: { id: postId }, select: { id: true } });
    if (!post) throw new NotFoundException('Postingan tidak ditemukan.');
    await this.prisma.socialPostLike.upsert({
      where: { postId_userId: { postId, userId } },
      create: { postId, userId },
      update: {},
    });
    return { liked: true };
  }

  async unlikePost(userId: string, postId: string) {
    await this.prisma.socialPostLike.deleteMany({ where: { postId, userId } });
    return { liked: false };
  }

  async listComments(postId: string) {
    const post = await this.prisma.socialPost.findUnique({ where: { id: postId }, select: { id: true } });
    if (!post) throw new NotFoundException('Postingan tidak ditemukan.');
    return this.prisma.socialPostComment.findMany({
      where: { postId }, orderBy: { createdAt: 'asc' }, take: 100,
      include: { user: { include: { profile: true } } },
    }).then((items) => items.map((item) => ({
      id: item.id, postId: item.postId, content: item.content, createdAt: item.createdAt,
      userId: item.userId, authorName: item.user.profile?.displayName ?? 'Pengguna MAVO',
      avatarUrl: item.user.profile?.avatarUrl ?? null,
    })));
  }

  async createComment(userId: string, postId: string, contentInput: string) {
    const content = contentInput?.trim() ?? '';
    if (!content || content.length > 2000) throw new BadRequestException('Komentar wajib diisi (maksimal 2000 karakter).');
    const post = await this.prisma.socialPost.findUnique({ where: { id: postId }, select: { id: true } });
    if (!post) throw new NotFoundException('Postingan tidak ditemukan.');
    const item = await this.prisma.socialPostComment.create({
      data: { postId, userId, content }, include: { user: { include: { profile: true } } },
    });
    return {
      id: item.id, postId, userId, content, createdAt: item.createdAt,
      authorName: item.user.profile?.displayName ?? 'Pengguna MAVO',
    };
  }

  async follow(followerId: string, followingId: string) {
    if (followerId === followingId) throw new BadRequestException('Kamu tidak bisa mengikuti akun sendiri.');
    const target = await this.prisma.user.findFirst({ where: { id: followingId, status: 'ACTIVE' }, select: { id: true } });
    if (!target) throw new NotFoundException('Pengguna tidak ditemukan.');
    await this.prisma.socialFollow.upsert({
      where: { followerId_followingId: { followerId, followingId } },
      create: { followerId, followingId }, update: {},
    });
    return { following: true };
  }

  async unfollow(followerId: string, followingId: string) {
    await this.prisma.socialFollow.deleteMany({ where: { followerId, followingId } });
    return { following: false };
  }

  async profile(viewerId: string, userId: string) {
    const user = await this.prisma.user.findFirst({
      where: { id: userId, status: 'ACTIVE' },
      include: { profile: true, creatorVerification: true, _count: { select: { socialPosts: true, socialFollowers: true, socialFollows: true } } },
    });
    if (!user) throw new NotFoundException('Profil tidak ditemukan.');
    const following = viewerId === userId ? false : !!(await this.prisma.socialFollow.findUnique({
      where: { followerId_followingId: { followerId: viewerId, followingId: userId } }, select: { id: true },
    }));
    return {
      id: user.id, displayName: user.profile?.displayName ?? 'Pengguna MAVO',
      avatarUrl: user.profile?.avatarUrl ?? null, bio: user.profile?.bio ?? '',
      city: user.profile?.city ?? null, province: user.profile?.province ?? null,
      postsCount: user._count.socialPosts, followersCount: user._count.socialFollowers,
      followingCount: user._count.socialFollows, following,
      creatorVerificationStatus: user.creatorVerification?.status ?? 'NOT_STARTED',
      creatorVerificationRejectionReason: user.creatorVerification?.rejectionReason ?? null,
    };
  }

  async searchUsers(viewerId: string, queryInput: string) {
    const query = queryInput.trim().slice(0, 80);
    if (query.length < 2) return [];
    const users = await this.prisma.user.findMany({
      where: {
        id: { not: viewerId }, status: 'ACTIVE',
        profile: { is: { displayName: { contains: query, mode: 'insensitive' } } },
      },
      take: 20, orderBy: { createdAt: 'desc' },
      include: { profile: true },
    });
    return users.map((user) => ({
      id: user.id, displayName: user.profile?.displayName ?? 'Pengguna MAVO',
      avatarUrl: user.profile?.avatarUrl ?? null, bio: user.profile?.bio ?? '',
    }));
  }

  async listStories(userId: string) {
    const follows = await this.prisma.socialFollow.findMany({ where: { followerId: userId }, select: { followingId: true } });
    const followedIds = follows.map((item) => item.followingId);
    const stories = await this.prisma.socialStory.findMany({
      where: {
        expiresAt: { gt: new Date() },
        OR: [
          { authorId: userId },
          { audience: 'PUBLIC' },
          { audience: 'FOLLOWERS', authorId: { in: followedIds } },
        ],
      },
      orderBy: { createdAt: 'desc' }, take: 100,
      include: { author: { include: { profile: true } }, media: true },
    });
    return stories.map((story) => ({
      id: story.id, authorId: story.authorId,
      authorName: story.author.profile?.displayName ?? 'Pengguna MAVO',
      content: story.content, createdAt: story.createdAt, expiresAt: story.expiresAt,
      media: story.media,
    }));
  }
}
