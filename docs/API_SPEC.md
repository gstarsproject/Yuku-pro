# YUKU API Specification v1.0

Base path: `/api/v1`  
Format: JSON over HTTPS. Timestamps: ISO-8601 UTC. IDs: UUID.

## Conventions
- Authentication: `Authorization: Bearer <access_token>` (to be implemented).
- Pagination: `?page=1&limit=20`; return `items`, `page`, `limit`, `total`.
- Mutating requests should accept `Idempotency-Key` where duplicate execution could charge, book, refund, or pay out.
- Errors: `{ "statusCode": 400, "code": "VALIDATION_ERROR", "message": "..." }`.
- Never trust client-supplied provider ID, price, fee, payment status, or role. Recalculate and authorize server-side.

## Public / customer endpoints
| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | Health check |
| GET | `/categories` | List published categories |
| GET | `/services` | Search published services |
| GET | `/services/:id` | Service detail |
| GET | `/providers/:id` | Public provider profile |
| GET | `/providers/:id/availability` | Available time slots |
| POST | `/bookings` | Create booking request |
| GET | `/bookings` | Current user's bookings |
| GET | `/bookings/:id` | Booking detail |
| POST | `/bookings/:id/cancel` | Request cancellation |
| POST | `/bookings/:id/complete` | Confirm completion (authorized flow) |
| POST | `/bookings/:id/disputes` | Open dispute |
| POST | `/payments/checkout` | Create gateway checkout |
| POST | `/payments/webhooks/:provider` | Signed gateway webhook |
| POST | `/reviews` | Submit review for eligible booking |
| GET | `/conversations` | List conversations |
| GET | `/conversations/:id/messages` | List messages |

## Account / provider endpoints
| Method | Path | Purpose |
|---|---|---|
| POST | `/auth/register` | Register account |
| POST | `/auth/login` | Login |
| POST | `/auth/otp/request` | Request OTP |
| POST | `/auth/otp/verify` | Verify OTP |
| GET | `/me` | Current profile |
| PATCH | `/me` | Update profile |
| POST | `/provider/onboarding` | Start provider onboarding |
| POST | `/provider/documents` | Submit verification document |
| POST | `/provider/services` | Create service |
| PATCH | `/provider/services/:id` | Update own service |
| GET | `/provider/bookings` | Provider booking inbox |
| POST | `/provider/bookings/:id/accept` | Accept request |
| POST | `/provider/bookings/:id/reject` | Reject request |
| GET | `/provider/earnings` | Earnings summary |
| POST | `/provider/payout-requests` | Request payout |

## Creator verification
| Method | Path | Purpose |
|---|---|---|
| GET | `/creator-verification/me` | Get current creator verification status |
| POST | `/creator-verification/document-upload-url` | Create a short-lived upload URL for a private evidence image (JPG/PNG/WEBP, max 10 MB) |
| POST | `/creator-verification` | Submit or resubmit creator verification request with 1–3 uploaded evidence keys |
| GET | `/admin/creators/pending` | Admin review queue |
| POST | `/admin/creators/:id/review` | Approve or reject a creator verification request |

Evidence is uploaded to the private `mavo-media` bucket under the authenticated user's `creator-verification/<userId>/` prefix. The API verifies ownership and object existence before accepting a request. Only admins receive short-lived evidence download URLs in the review queue. A creator badge is displayed only when the server returns `creatorVerificationStatus: VERIFIED` / `authorVerified: true`. A rejected request includes a reason and may be resubmitted. Requests in `PENDING` or `VERIFIED` cannot be duplicated.

## Admin endpoints (role protected)
| Method | Path | Purpose |
|---|---|---|
| GET | `/admin/overview` | Business metrics |
| GET | `/admin/providers/pending` | Verification queue |
| POST | `/admin/providers/:id/verification` | Approve/reject with audit |
| GET | `/admin/disputes` | Dispute queue |
| POST | `/admin/disputes/:id/resolve` | Resolve dispute |
| GET | `/admin/audit-logs` | Audit events |

## Booking request example
```json
{
  "serviceId": "uuid",
  "serviceMode": "OFFLINE",
  "startsAt": "2026-12-01T03:00:00.000Z",
  "durationMinutes": 120,
  "attendeeCount": 1,
  "location": {
    "city": "Bogor",
    "address": "Shared after provider accepts"
  },
  "customerNote": "Meet at agreed public location"
}
```

## Booking response (illustrative)
```json
{
  "id": "uuid",
  "status": "PENDING_PROVIDER",
  "currency": "IDR",
  "priceBreakdown": {
    "serviceAmount": 250000,
    "platformFee": 0,
    "travelFee": 0,
    "total": 250000
  }
}
```
The server must calculate the actual price breakdown. The values above are examples only.

## Booking state machine
`PENDING_PROVIDER -> ACCEPTED -> AWAITING_PAYMENT -> PAID -> IN_PROGRESS -> COMPLETED`
Alternative transitions: `REJECTED`, `CANCELLED`, `DISPUTED`, `REFUNDED`. Transitions must be enforced on the server and recorded in an immutable event/audit history.

## Payment safety
- Verify webhook signatures.
- Use idempotency and unique gateway references.
- Reconcile gateway settlements.
- Never mark payment successful based only on a mobile callback.
- Store gateway tokens/references, not raw card data.
