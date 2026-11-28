CREATE TYPE "SocialAudience" AS ENUM ('PUBLIC', 'FOLLOWERS', 'PRIVATE');
CREATE TYPE "SocialMediaType" AS ENUM ('IMAGE', 'VIDEO');

CREATE TABLE "SocialPost" (
  "id" UUID NOT NULL,
  "authorId" UUID NOT NULL,
  "content" VARCHAR(2000) NOT NULL,
  "audience" "SocialAudience" NOT NULL DEFAULT 'PUBLIC',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "SocialPost_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "SocialPostMedia" (
  "id" UUID NOT NULL,
  "postId" UUID NOT NULL,
  "objectKey" TEXT NOT NULL,
  "mediaType" "SocialMediaType" NOT NULL,
  "contentType" TEXT NOT NULL,
  "byteSize" INTEGER NOT NULL,
  "position" INTEGER NOT NULL DEFAULT 0,
  CONSTRAINT "SocialPostMedia_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "SocialPostLike" (
  "id" UUID NOT NULL,
  "postId" UUID NOT NULL,
  "userId" UUID NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "SocialPostLike_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "SocialPostComment" (
  "id" UUID NOT NULL,
  "postId" UUID NOT NULL,
  "userId" UUID NOT NULL,
  "content" VARCHAR(2000) NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "SocialPostComment_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "SocialFollow" (
  "id" UUID NOT NULL,
  "followerId" UUID NOT NULL,
  "followingId" UUID NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "SocialFollow_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "SocialStory" (
  "id" UUID NOT NULL,
  "authorId" UUID NOT NULL,
  "content" VARCHAR(500),
  "audience" "SocialAudience" NOT NULL DEFAULT 'PUBLIC',
  "expiresAt" TIMESTAMP(3) NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "SocialStory_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "SocialStoryMedia" (
  "id" UUID NOT NULL,
  "storyId" UUID NOT NULL,
  "objectKey" TEXT NOT NULL,
  "mediaType" "SocialMediaType" NOT NULL,
  "contentType" TEXT NOT NULL,
  "byteSize" INTEGER NOT NULL,
  CONSTRAINT "SocialStoryMedia_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "SocialStoryView" (
  "id" UUID NOT NULL,
  "storyId" UUID NOT NULL,
  "viewerId" UUID NOT NULL,
  "viewedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "SocialStoryView_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "SocialPost_createdAt_idx" ON "SocialPost"("createdAt");
CREATE INDEX "SocialPost_authorId_createdAt_idx" ON "SocialPost"("authorId", "createdAt");
CREATE INDEX "SocialPost_audience_createdAt_idx" ON "SocialPost"("audience", "createdAt");
CREATE INDEX "SocialPostMedia_postId_position_idx" ON "SocialPostMedia"("postId", "position");
CREATE UNIQUE INDEX "SocialPostLike_postId_userId_key" ON "SocialPostLike"("postId", "userId");
CREATE INDEX "SocialPostLike_userId_createdAt_idx" ON "SocialPostLike"("userId", "createdAt");
CREATE INDEX "SocialPostComment_postId_createdAt_idx" ON "SocialPostComment"("postId", "createdAt");
CREATE INDEX "SocialPostComment_userId_createdAt_idx" ON "SocialPostComment"("userId", "createdAt");
CREATE UNIQUE INDEX "SocialFollow_followerId_followingId_key" ON "SocialFollow"("followerId", "followingId");
CREATE INDEX "SocialFollow_followingId_createdAt_idx" ON "SocialFollow"("followingId", "createdAt");
CREATE INDEX "SocialStory_expiresAt_idx" ON "SocialStory"("expiresAt");
CREATE INDEX "SocialStory_authorId_createdAt_idx" ON "SocialStory"("authorId", "createdAt");
CREATE UNIQUE INDEX "SocialStoryView_storyId_viewerId_key" ON "SocialStoryView"("storyId", "viewerId");
CREATE INDEX "SocialStoryView_viewerId_viewedAt_idx" ON "SocialStoryView"("viewerId", "viewedAt");

ALTER TABLE "SocialPost" ADD CONSTRAINT "SocialPost_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SocialPostMedia" ADD CONSTRAINT "SocialPostMedia_postId_fkey" FOREIGN KEY ("postId") REFERENCES "SocialPost"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SocialPostLike" ADD CONSTRAINT "SocialPostLike_postId_fkey" FOREIGN KEY ("postId") REFERENCES "SocialPost"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SocialPostLike" ADD CONSTRAINT "SocialPostLike_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SocialPostComment" ADD CONSTRAINT "SocialPostComment_postId_fkey" FOREIGN KEY ("postId") REFERENCES "SocialPost"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SocialPostComment" ADD CONSTRAINT "SocialPostComment_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SocialFollow" ADD CONSTRAINT "SocialFollow_followerId_fkey" FOREIGN KEY ("followerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SocialFollow" ADD CONSTRAINT "SocialFollow_followingId_fkey" FOREIGN KEY ("followingId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SocialStory" ADD CONSTRAINT "SocialStory_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SocialStoryMedia" ADD CONSTRAINT "SocialStoryMedia_storyId_fkey" FOREIGN KEY ("storyId") REFERENCES "SocialStory"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SocialStoryView" ADD CONSTRAINT "SocialStoryView_storyId_fkey" FOREIGN KEY ("storyId") REFERENCES "SocialStory"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SocialStoryView" ADD CONSTRAINT "SocialStoryView_viewerId_fkey" FOREIGN KEY ("viewerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
