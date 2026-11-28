# API contract draft

All endpoints require HTTPS in production and authenticated JWT unless stated otherwise.

| Method | Path | Purpose |
|---|---|---|
| POST | `/v1/bookings` | Create Instant or Request booking |
| POST | `/v1/provider/bookings/:id/respond` | Accept/reject Request |
| POST | `/v1/payments/bookings/:id/checkout` | Create gateway checkout |
| POST | `/v1/payments/webhook/:provider` | Verified gateway webhook |
| POST | `/v1/provider/bookings/:id/start` | Start service |
| POST | `/v1/provider/bookings/:id/submit-completion` | Submit service completion |
| POST | `/v1/customer/bookings/:id/confirm-completion` | Confirm completion |
| POST | `/v1/provider/payouts` | Request payout |
| GET | `/v1/provider/payouts` | Provider payout history |
| GET | `/v1/customer/bookings` | Customer booking history |
| GET | `/v1/provider/bookings` | Provider booking inbox |

Request payloads must never supply customer/provider IDs, final price, commission rate, provider net, or payment status. Derive these values from the authenticated user, database and verified payment provider.
