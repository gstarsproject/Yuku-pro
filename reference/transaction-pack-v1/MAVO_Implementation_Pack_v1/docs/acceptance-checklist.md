# Acceptance checklist before real launch

- [ ] Auth guards and role/ownership checks on every endpoint
- [ ] Category commission editable by admin, with historical rate snapshotted per booking
- [ ] Booking overlap race test with concurrent requests
- [ ] Request booking accept/reject tests
- [ ] Instant booking checkout tests
- [ ] Payment webhook signature verification tests
- [ ] Duplicate/out-of-order webhook tests
- [ ] Amount/currency mismatch rejection
- [ ] Completion confirmation and ledger atomicity tests
- [ ] Duplicate payout prevention tests
- [ ] Verified bank account and disbursement integration
- [ ] Refund and dispute workflow
- [ ] Audit logs, monitoring, alerting, backups and restore test
- [ ] Privacy policy, terms, cancellation/refund policy and provider agreement
- [ ] Payment provider approval for marketplace model
- [ ] End-to-end tests on Android and iOS
