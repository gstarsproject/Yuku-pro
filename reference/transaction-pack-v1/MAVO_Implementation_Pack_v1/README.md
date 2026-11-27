# YUKU Implementation Pack v1 — Transaction Core

This package is an implementation foundation for YUKU's marketplace transaction domain.
It is **not yet a production-ready marketplace**. It includes a PostgreSQL/Prisma data model,
NestJS transaction module scaffolding, booking/payment/payout rules, and setup notes.

## Decisions encoded
- Booking modes: `INSTANT` and `REQUEST`
- Commission: configurable per service category (rates are admin-configurable; sample seed values are illustrative only)
- Provider payout: eligible only after service completion and customer confirmation (or an admin-controlled dispute resolution)
- Payment: gateway adapter boundary; no live credentials or live money movement included

## Important safety/financial rules
1. Never mark an order paid from a client redirect. Only a verified gateway webhook can do that.
2. Verify webhook signatures and make webhook processing idempotent.
3. Never store card numbers, CVV, or raw payment credentials.
4. Keep immutable ledger entries; do not calculate balances by trusting client input.
5. Do not describe a provider balance as withdrawable until payout eligibility checks pass.
6. Use a payment provider's approved marketplace/disbursement product and obtain legal/accounting review before holding or splitting funds.

## Contents
- `database/schema.prisma`: core relational schema
- `backend/src/transactions`: DTOs, service/controller skeleton, status transitions
- `backend/src/payments`: gateway interface and webhook skeleton
- `backend/src/payouts`: payout eligibility and request skeleton
- `docs/`: lifecycle, API contract, acceptance checklist
- `.env.example`: local configuration template

## Next implementation steps
1. Add authentication/authorization guards and user ownership checks.
2. Implement the selected payment provider adapter and signature verification.
3. Add migrations and integration tests against PostgreSQL.
4. Add provider calendar locking and race-condition tests.
5. Integrate customer/provider screens and admin operations.
6. Run security, accounting, refund, dispute, and load testing before launch.
