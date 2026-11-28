# Booking, payment, commission and payout lifecycle

## Booking modes
- **INSTANT**: create booking in `PENDING_PAYMENT`; customer proceeds to checkout.
- **REQUEST**: create booking in `PENDING_PROVIDER`; provider accepts or rejects. On accept, move to `PENDING_PAYMENT`.

## Payment
- Backend creates checkout using server-calculated amount.
- Customer completes payment on gateway-hosted checkout.
- Browser/app redirect is informational only.
- Verified webhook is the only source that changes payment to `PAID`.
- Webhook event ID and payment reference must be unique/idempotent.

## Service completion
1. Provider starts service: `CONFIRMED -> IN_SERVICE`.
2. Provider submits completion: `IN_SERVICE -> COMPLETION_SUBMITTED`.
3. Customer confirms: `COMPLETION_SUBMITTED -> COMPLETED`.
4. Backend writes provider earning and platform commission ledger entries atomically.
5. Only then can that earning be included in a payout request.

## Payout
- Provider requests payout against eligible ledger earnings.
- System prevents using the same booking earning twice.
- Admin reviews payout and verifies provider's bank account.
- Approved payout is sent using the gateway/bank disbursement product.
- A verified disbursement result updates payout to `PAID`.
- Never mark payout paid just because an admin clicked a button; require provider confirmation or bank/gateway status.

## Critical production work
- Database-level schedule overlap prevention (e.g. PostgreSQL exclusion constraint on provider + time range).
- Serializable transactions or advisory locks for booking creation.
- Cancellation/refund policy and dispute workflow.
- Payout reserve, minimum threshold, fees, tax, reconciliation and statements.
- Role-based access control and audit logs.
