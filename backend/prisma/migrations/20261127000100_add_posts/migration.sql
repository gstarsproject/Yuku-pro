-- MAVO Social Feed: text posts and audience visibility
CREATE TABLE "Post" (
  "id" UUID NOT NULL,
  "authorId" UUID NOT NULL,
  "content" VARCHAR(2000) NOT NULL,
  "audience" TEXT NOT NULL DEFAULT 'PUBLIC',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Post_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "Post_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "Post_audience_check" CHECK ("audience" IN ('PUBLIC','FOLLOWERS','PRIVATE'))
);
CREATE INDEX "Post_createdAt_idx" ON "Post"("createdAt");
CREATE INDEX "Post_authorId_createdAt_idx" ON "Post"("authorId","createdAt");