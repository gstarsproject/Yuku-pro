ALTER TABLE "ContentReport"
  ADD COLUMN "postId" UUID,
  ADD COLUMN "reportType" VARCHAR(20) NOT NULL DEFAULT 'USER';

DROP INDEX IF EXISTS "ContentReport_reporterId_targetUserId_key";

ALTER TABLE "ContentReport"
  ADD CONSTRAINT "ContentReport_postId_fkey"
  FOREIGN KEY ("postId") REFERENCES "Post"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;

CREATE INDEX "ContentReport_postId_createdAt_idx"
  ON "ContentReport"("postId","createdAt");

CREATE UNIQUE INDEX "ContentReport_user_report_unique"
  ON "ContentReport"("reporterId","targetUserId")
  WHERE "reportType" = 'USER';

CREATE UNIQUE INDEX "ContentReport_post_report_unique"
  ON "ContentReport"("reporterId","postId")
  WHERE "reportType" = 'POST' AND "postId" IS NOT NULL;

ALTER TABLE "ContentReport"
  ADD CONSTRAINT "ContentReport_report_type_check"
  CHECK ("reportType" IN ('USER','POST'));
