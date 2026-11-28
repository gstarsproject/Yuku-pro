CREATE TABLE "UserBlock" (
  "id" UUID NOT NULL,
  "blockerId" UUID NOT NULL,
  "blockedId" UUID NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "UserBlock_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "UserBlock_blockerId_fkey" FOREIGN KEY ("blockerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "UserBlock_blockedId_fkey" FOREIGN KEY ("blockedId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "UserBlock_not_self_check" CHECK ("blockerId" <> "blockedId")
);
CREATE UNIQUE INDEX "UserBlock_blockerId_blockedId_key" ON "UserBlock"("blockerId","blockedId");
CREATE INDEX "UserBlock_blockedId_createdAt_idx" ON "UserBlock"("blockedId","createdAt");

CREATE TABLE "ContentReport" (
  "id" UUID NOT NULL,
  "reporterId" UUID NOT NULL,
  "targetUserId" UUID NOT NULL,
  "reason" VARCHAR(80) NOT NULL,
  "details" VARCHAR(1000),
  "status" VARCHAR(20) NOT NULL DEFAULT 'OPEN',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "ContentReport_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "ContentReport_reporterId_fkey" FOREIGN KEY ("reporterId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "ContentReport_targetUserId_fkey" FOREIGN KEY ("targetUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "ContentReport_not_self_check" CHECK ("reporterId" <> "targetUserId")
);
CREATE UNIQUE INDEX "ContentReport_reporterId_targetUserId_key" ON "ContentReport"("reporterId","targetUserId");
CREATE INDEX "ContentReport_status_createdAt_idx" ON "ContentReport"("status","createdAt");
CREATE INDEX "ContentReport_targetUserId_createdAt_idx" ON "ContentReport"("targetUserId","createdAt");
