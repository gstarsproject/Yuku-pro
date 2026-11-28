ALTER TYPE "BookingStatus" ADD VALUE IF NOT EXISTS 'AWAITING_CONFIRMATION';
ALTER TABLE "LedgerEntry" ADD COLUMN "idempotencyKey" TEXT;
CREATE UNIQUE INDEX "LedgerEntry_idempotencyKey_key" ON "LedgerEntry"("idempotencyKey");
