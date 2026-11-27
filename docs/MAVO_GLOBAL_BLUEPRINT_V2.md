# MAVO Global Blueprint V2
## Global Service & Experience Marketplace

**Positioning:** MAVO is a global-ready marketplace connecting customers with people, experiences, and professional services.

**Brand promise:** Connect. Experience. Get Things Done.

## 1. Product pillars

### FRIEND
Social and activity companionship, conversation, local guides, and shared activities. This category requires strict consent, identity verification, anti-harassment controls, clear service boundaries, and safety reporting.

### EXPERIENCE
Tours, classes, events, activities, entertainment, and bookable experiences, online or offline.

### PRO
Professional services, consulting, specialist skills, and task-based services. Professional credentials may be required depending on service and country.

## 2. Product roles

- Customer: discovers services, books, pays, chats, confirms completion, reviews, and raises disputes.
- Provider: creates a profile, passes verification, publishes services, manages availability and bookings, communicates, and receives payouts.
- Admin/support: reviews verification, moderates services, handles disputes/refunds, configures commissions, monitors payments and payouts, and manages country-specific rules.

## 3. Core customer journey

1. Select language and country/region.
2. Discover by pillar, category, location, date, price, rating, and online/offline mode.
3. View provider profile, verification status, reviews, service terms, price, and availability.
4. Choose Instant Booking or Request Booking.
5. Review full price breakdown and pay through an available local payment method.
6. Chat and receive booking updates.
7. Provider completes the service; customer confirms or opens a dispute.
8. Release provider payout only after the applicable completion and dispute rules are satisfied.
9. Customer reviews the service and may earn eligible rewards.

## 4. Booking and transaction rules

- Booking modes: INSTANT and REQUEST.
- Service modes: ONLINE, OFFLINE, and BOTH.
- A booking must snapshot its service amount, currency, platform fee, travel fee, total, and applicable commission rule so later price changes do not rewrite past transactions.
- Payment status and booking status must be separate state machines.
- Payment webhooks must be signature-verified, idempotent, and stored for audit.
- Never mark a booking paid based only on a client-side redirect.
- Provider payout must be held until service completion is confirmed and any dispute hold is resolved.
- Refund, cancellation, partial refund, chargeback, and payout reversal flows must be explicitly defined.
- All money values use integer minor units (for example, cents) with an ISO 4217 currency code. Never use floating-point arithmetic for money.
- Commission is configurable by category, country, and effective date. Do not hardcode the draft percentages in production.

## 5. Global-readiness requirements

### Localization
- Translation keys, not hardcoded UI strings.
- Initial languages: Indonesian and English.
- Design for additional languages and right-to-left layouts.
- Store timestamps in UTC; display in the customer's/provider's relevant timezone.
- Persist IANA timezone identifiers (for example, Asia/Jakarta), not only numeric offsets.

### Country and currency
- Add country/region configuration and supported service markets.
- Use ISO 3166-1 alpha-2 country codes and ISO 4217 currency codes.
- Store the currency used for each service, booking, payment, refund, ledger entry, and payout.
- Add FX quote/provider, rate, quote timestamp, and expiry only when cross-currency conversion is offered.
- Show customers the final charge currency and any conversion disclosure before payment.
- Country-specific payment providers, taxes, consumer rights, privacy rules, and provider onboarding must be configurable.

### Marketplace trust
- Identity verification and provider verification are separate concepts.
- Review eligibility only after an eligible completed booking.
- Add report/block, moderation queue, evidence handling, safety escalation, and account sanctions.
- For offline bookings, consider optional trip sharing, emergency contact, and check-in/out flows.
- FRIEND category must have explicit service boundaries and prohibited conduct rules.

## 6. Differentiating capabilities (phased)

- MAVO Verified: identity, credentials, and provider quality checks.
- MAVO AI Match: explainable matching by category, location, availability, budget, language, rating, and customer preferences. AI must not make high-impact verification or safety decisions alone.
- MAVO Live: in-app video consultation/calls where appropriate, with consent and abuse reporting.
- MAVO Rewards: points, vouchers, referral, and membership with transparent terms.
- MAVO Partner: provider dashboard for profile, listings, availability, bookings, analytics, earnings, and payout status.
- Smart search: filters and ranking with transparent sponsored placement labels if ads are introduced.

## 7. Current repository baseline (reviewed 2026-11-27)

### Present in Prisma schema
- User roles and account status.
- Customer profile and provider profile.
- Provider verification status, languages, rating, review count, and completed-booking count.
- Category and service catalog.
- Online/offline/both service mode.
- Availability.
- Booking and payment records.
- Ledger entries, reviews, verification documents, conversations/messages, disputes.
- Category commission rules with basis-point rates.
- Provider payout records and payment webhook event records.

### Present in Cloudflare Worker scaffold
- Health endpoint and database health endpoint.
- Read endpoints for active categories, published service search, and service detail.
- PostgreSQL connectivity through Cloudflare Hyperdrive.

### Present in Flutter app
- Home and Explore screens.
- Health indicator and service/category data access.
- Bottom navigation for Home, Explore, Booking, Chat, and Profile.
- Booking, Chat, and Profile are currently placeholders.
- Home category tiles are currently visual and not yet wired to Explore filters.

### Not yet implemented or not yet verified as production-ready
- Production authentication, registration, session/JWT handling, role authorization, and account recovery.
- Provider onboarding, document upload/review workflow, service CRUD, and availability management.
- Booking create/accept/reject/cancel/complete endpoints and concurrency-safe availability reservation.
- Payment creation, verified webhook processing, refunds, disputes workflow, and payout execution.
- Real-time chat delivery, push notifications, and moderation tooling.
- Admin operations beyond the existing initial dashboard.
- Global country configuration, localization catalog, FX conversion, local tax/compliance rules, and country payment routing.
- AI matching, live calls, rewards, and partner analytics.
- End-to-end security, load, payment, and store-release testing.

## 8. Recommended architecture

- Flutter app: customer/provider experience, role-aware navigation, localization, secure token storage.
- Cloudflare Worker API: versioned REST API, validation, authentication middleware, authorization, rate limits, idempotency, and audit logging.
- Neon PostgreSQL via Hyperdrive: transactional source of truth.
- Object storage: verification documents and user media with private access and signed URLs.
- Payment adapter layer: provider-specific integrations behind a common interface; begin with Midtrans sandbox for Indonesia.
- Notifications: push/email/SMS adapters, with consent and delivery logs.
- Admin web: verification, moderation, catalog, booking, payment, dispute, commission, payout, country configuration, and audit tools.
- Observability: structured logs, error monitoring, traces, alerts, and operational dashboards.

## 9. Data model additions to plan (do not migrate blindly)

1. CountryMarket: countryCode, defaultCurrency, defaultLanguage, timezone policy, enabled status, market launch status.
2. SupportedLanguage / Translation: locale and translation keys for managed content where needed.
3. CurrencyRate / FxQuote: base, quote, rate, provider, quotedAt, expiresAt (only if FX conversion is offered).
4. CountryPaymentMethod: country, gateway, method, currency, enabled status.
5. CommissionRule extension: optional country/market scope, effectiveFrom/effectiveTo, priority, and immutable booking snapshot.
6. Booking snapshot: commission rule/rate, customer display currency if converted, FX rate and quote ID where applicable, cancellation policy snapshot.
7. Payout destination and payout attempt records with encrypted/sensitive-field handling and audit history.
8. SafetyReport / BlockedUser / ModerationAction / AuditLog.
9. NotificationPreference and NotificationDelivery.
10. IdempotencyKey or equivalent request-idempotency records for money-moving operations.

Before migrations, inspect existing data and constraints, design backward-compatible migrations, and take a database backup.

## 10. Delivery roadmap

### Phase 0 — Stabilize the current app
- Verify current APK on device.
- Verify health, database health, category list, service list, and service detail from the actual phone.
- Fix app errors and wire Home category tiles to Explore.
- Reduce debug APK size; create signed release build only after release configuration and signing are safely established.

### Phase 1 — Secure foundation
- Production authentication and role authorization.
- API request validation, rate limiting, secure secrets, audit logs, and account recovery.
- Provider onboarding and verification workflow.
- Admin access controls and moderation basics.

### Phase 2 — Working marketplace MVP
- Provider service CRUD and availability.
- Booking request/instant flows with race-condition protection.
- Midtrans sandbox payment creation and verified webhooks.
- Completion confirmation, dispute hold, refunds, commission ledger, and payout workflow.
- Booking, chat, and profile screens connected to real APIs.

### Phase 3 — Indonesia launch readiness
- Indonesian localization, IDR, Indonesian payment methods.
- Customer support, safety policies, provider quality operations.
- Privacy, terms, cancellation/refund rules, tax and legal review.
- End-to-end and security testing.

### Phase 4 — Global expansion foundation
- Country-market configuration, English localization, timezone handling.
- Payment adapter and currency-aware transaction design.
- Country-specific compliance and operational playbooks.
- Pilot one additional market only after Indonesia marketplace metrics are healthy.

### Phase 5 — Differentiation and scale
- AI Match, MAVO Live, Rewards, Partner analytics.
- Search ranking quality, fraud/risk controls, reliability and performance.
- Expand country by country based on unit economics and provider/customer liquidity.

## 11. Launch metrics

Track by country and pillar:
- Search-to-service-detail conversion.
- Detail-to-booking conversion.
- Booking acceptance rate and time to accept.
- Payment success rate.
- Completion and cancellation rates.
- Dispute, refund, fraud, and safety incident rates.
- Repeat booking and 30/90-day retention.
- Active quality providers and service coverage by city/category.
- Contribution margin after payment, support, refunds, and incentives.

## 12. Non-negotiable engineering rules

- No production secrets in source code, GitHub commits, or chat.
- Rotate any database credential that has been exposed.
- Never trust client-provided role, price, commission, payment status, or payout status.
- Enforce authorization on every protected endpoint.
- Use database transactions and idempotency for payment, booking, ledger, refund, and payout operations.
- Keep audit trails for admin and money-moving actions.
- Do not launch a new country until local payment, privacy, consumer, tax, and safety requirements are reviewed.
- Treat this blueprint as a target architecture; only mark a feature complete after implementation and testing.
