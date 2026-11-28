CREATE TABLE "Story" (
  "id" UUID NOT NULL,
  "userId" UUID NOT NULL,
  "content" VARCHAR(500) NOT NULL,
  "audience" TEXT NOT NULL DEFAULT 'PUBLIC',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "expiresAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Story_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "Story_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "Story_expiresAt_idx" ON "Story"("expiresAt");
CREATE INDEX "Story_userId_createdAt_idx" ON "Story"("userId","createdAt");
