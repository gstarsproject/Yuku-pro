-- MAVO Social Feed: persistent likes and comments
CREATE TABLE "PostLike" (
  "id" UUID NOT NULL,
  "postId" UUID NOT NULL,
  "userId" UUID NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "PostLike_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "PostLike_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "PostLike_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "PostLike_postId_userId_key" ON "PostLike"("postId","userId");
CREATE INDEX "PostLike_userId_createdAt_idx" ON "PostLike"("userId","createdAt");
CREATE TABLE "PostComment" (
  "id" UUID NOT NULL,
  "postId" UUID NOT NULL,
  "userId" UUID NOT NULL,
  "content" VARCHAR(1000) NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "PostComment_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "PostComment_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "PostComment_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "PostComment_postId_createdAt_idx" ON "PostComment"("postId","createdAt");
CREATE INDEX "PostComment_userId_createdAt_idx" ON "PostComment"("userId","createdAt");
