# MAVO UI/UX Screen Specification v1.0

## Global navigation
Mobile bottom navigation:
1. Home
2. Explore
3. Bookings
4. Chat
5. Profile

Provider Center is entered from Profile and can also be switched to from the account menu. Admin is a separate web application.

## Customer screens

### A. Onboarding and account
- Splash: MAVO logo, slogan, loading state.
- Intro: explain Friend, Experience, Pro; skip and continue.
- Location permission explainer: request only when user uses nearby search; allow manual city selection.
- Sign up: phone/email, password, terms and privacy consent.
- Login: phone/email and password.
- OTP verification: resend timer, attempt limit, change contact.
- Forgot password: secure recovery flow.

### B. Home
- Header: selected city, notifications, profile shortcut.
- Search bar: “Cari teman atau jasa…”
- Three category tiles: Friend, Experience, Pro.
- Featured services and recommended providers.
- Popular near selected city.
- Trust education banner and recently viewed.
- Empty/loading/error states.

### C. Explore and search
- Search input and recent searches.
- Category and subcategory filters.
- Filters: city/area, online/offline, date, price range, rating, verified status, service type.
- Sort: recommended, nearest, price, rating.
- Map/list toggle; map access is optional and location permission is contextual.
- Result card: photo, provider name, service title, price unit, rating count, verification label, service mode.

### D. Service detail
- Gallery/portfolio.
- Provider identity and verification status.
- Service description, inclusions/exclusions, duration and price unit.
- Online/offline mode and service area.
- Availability preview.
- Reviews with count and distribution.
- Cancellation/refund summary.
- CTA: “Pilih jadwal”.

### E. Provider profile
- Photo, name, city, verification state.
- Bio, skills, languages, experience.
- Services and portfolio.
- Rating and completed booking count (only real values).
- Report/block actions.
- Message button subject to policy; booking CTA.

### F. Booking flow
1. Choose service option/package.
2. Select online/offline.
3. Select date, start time, duration, attendee count.
4. Enter service address or meeting point for offline service; show privacy warning.
5. Add booking notes and accessibility needs.
6. Review price breakdown, travel fees, platform fee, cancellation terms.
7. Submit booking request.
8. Provider accepts/rejects; accepted booking proceeds to payment according to configured payment policy.
9. Confirmation with booking reference and safety guidance.

### G. Payment and booking detail
- Payment method list from enabled gateway.
- Price breakdown and payment deadline.
- Payment pending/success/failed states.
- Booking timeline and provider contact.
- Cancel, reschedule, report, dispute, refund status.
- Completion confirmation and review prompt.

### H. Chat
- Conversation list linked to booking where possible.
- Message detail, text and approved attachments.
- Report/block, safety reminder, no sharing of payment credentials.
- Do not expose personal phone numbers by default.

### I. Bookings
- Tabs: Upcoming, In progress, Completed, Cancelled.
- Filters and booking detail.
- Reschedule/cancel based on policy.
- Dispute and support entry.

### J. Profile
- Personal details, saved providers, addresses, preferences.
- Payment methods managed by gateway/tokenization provider.
- Notification and privacy settings.
- Help center, report, logout, delete account request.

## Provider screens
- Provider onboarding: personal details, city, service categories, service mode.
- Identity verification: KYC provider integration or controlled admin review; secure document upload.
- Professional credentials: license/certificate requirements by category.
- Provider profile editor and portfolio.
- Service editor: title, description, inclusions, price, unit, duration, travel policy, online/offline.
- Availability calendar and blocked times.
- Booking requests: accept/reject with reason and response deadline.
- Active bookings: check-in, start, complete, evidence where appropriate.
- Earnings: gross, platform fee, adjustments, net payable, payout status.
- Payout account setup via compliant payout provider.
- Reviews, support, policy center.

## Admin screens (Next.js)
- Secure admin login with MFA in production.
- Overview: GMV, booking count, cancellation, disputes, active providers.
- Users: search, suspend, restore, audit trail.
- Providers: review KYC, credentials, service listings, verification status.
- Categories: create, edit, publish, archive.
- Services: moderation and listing review.
- Bookings: timeline and support actions.
- Payments: gateway references, reconciliation, refunds.
- Ledger and payouts: read-only ledger, controlled payout approval.
- Disputes: evidence, resolution, refund/partial refund actions.
- Reviews/reports: moderation queue.
- Configuration: fees, cancellation policies, service restrictions.
- Audit logs and role management.

## Shared states
Every data screen must implement loading, empty, error, offline, permission-denied, and retry states. Destructive actions require confirmation. Price and booking changes require a final review screen.
