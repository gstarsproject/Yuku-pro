CREATE TYPE "CreatorVerificationStatus" AS ENUM ('NOT_STARTED', 'PENDING', 'VERIFIED', 'REJECTED');

CREATE TABLE "CreatorVerificationRequest" (
  "id" UUID NOT NULL,
  "userId" UUID NOT NULL,
  "status" "CreatorVerificationStatus" NOT NULL DEFAULT 'PENDING',
  "creatorName" VARCHAR(80) NOT NULL,
  "handle" VARCHAR(80) NOT NULL,
  "category" VARCHAR(80) NOT NULL,
  "reason" VARCHAR(1000) NOT NULL,
  "documentKeys" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  "rejectionReason" VARCHAR(1000),
  "submittedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "reviewedAt" TIMESTAMP(3),
  "reviewedById" UUID,
  CONSTRAINT "CreatorVerificationRequest_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "CreatorVerificationRequest_userId_key" ON "CreatorVerificationRequest"("userId");
CREATE INDEX "CreatorVerificationRequest_status_submittedAt_idx" ON "CreatorVerificationRequest"("status", "submittedAt");
ALTER TABLE "CreatorVerificationRequest" ADD CONSTRAINT "CreatorVerificationRequest_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
