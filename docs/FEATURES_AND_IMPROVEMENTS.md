# Boklo Wallet — Complete Feature & Improvement Audit

> Date: 2026-09-18 · Verified against the repository at commit `588014f`.
> Every "EXISTING" claim below was verified in code (file:line where useful). Documentation claims were **not** trusted — several docs discrepancies were previously corrected in the modernization plan.

Status vocabulary:

- **EXISTING** — fully implemented and wired end-to-end.
- **PARTIAL** — implemented but incomplete or with dead branches.
- **MISSING** — not present anywhere.
- **IMPROVEMENT** — change to something that exists.
- **NEW FEATURE** — net-new capability.
- **OPTIONAL / FUTURE** — worthwhile but not now.
- **OUT OF SCOPE** — deliberately excluded from this product's direction.

Priority: **P0** critical · **P1** high · **P2** medium · **P3** optional.

---

## 1. Complete Current Feature Inventory

### Authentication & account

| Feature | Status | Evidence / notes |
| --- | --- | --- |
| Email/password registration | EXISTING | `auth_remote_data_source.dart` → Firebase Auth; backend `onUserCreated` provisions wallet/user doc/email identifier |
| Login / logout | EXISTING | `AuthCubit.login/logout`; logout deletes the FCM token doc first |
| Profile setup (username + display name) | EXISTING | `setUserProfile` callable: transactional username claim/release, reserved-word + length validation |
| Auth-guarded routing | EXISTING | `AppRouter.resolveRedirect` (pure, unit-tested); deep links protected |
| Account deletion (guarded) | EXISTING | `deleteAccount` callable: re-auth, zero-balance + no-history preconditions, full data cleanup incl. `wallet_public` |
| Session/device management (list/revoke other sessions) | MISSING | Only the current FCM token is managed |
| Biometric login / app lock | MISSING | `enableBiometrics` flag exists but **no code reads it** (verified: zero consumers) |
| Password reset/change | MISSING | No forgot-password flow in the app or functions |
| Email verification | MISSING | No `sendEmailVerification` anywhere |

### Wallet

| Feature | Status | Evidence / notes |
| --- | --- | --- |
| Wallet provisioning (idempotent callable + auth-trigger fallback) | EXISTING | `wallet.ts`, `users.ts`, `profile.ts` all create consistently with `minorUnits: true` |
| Balance display (minor units → `moneyLabel`) | EXISTING | `balance_card.dart` |
| Live balance via Firestore watch | EXISTING | `watch_wallet_usecase` → owner-only reads |
| Offline balance cache | PARTIAL | Secure-storage cache read **only** on fetch failure; no staleness marker; first page of transactions only |
| Wallet identity (username/alias badge, copy-to-clipboard) | EXISTING | `balance_card_badge.dart` |
| Multiple wallets per user | MISSING (by design, 1:1 uid-keyed) | Not a current goal |
| Wallet freeze/status (admin) | MISSING | `isActive` stored, never enforced client- or admin-side |

### Transfers

| Feature | Status | Evidence / notes |
| --- | --- | --- |
| Transfer creation (uuid id, idempotent doc write + backend execution) | EXISTING | Client `runTransaction` refuses ID collisions; `onTransferCreated` re-checks status in-txn |
| Backend-authoritative ledger movement | EXISTING | Atomic debit/credit + mirrored transaction records + `completed` status, all in one Firestore transaction |
| Integer minor units + fail-closed migration guard | EXISTING | `currenciesAreCompatible`/`hasMinorUnitsFlag` checks in-txn; runbook `docs/MONEY_MIGRATION.md` |
| Currency-integrity assertion (no cross-currency) | EXISTING | Strict equality of transfer/sender/receiver currency |
| Recipient resolution (wallet ID / `BOKLO-` alias / email / @username) | EXISTING | `_resolveWallet` → `wallet_public`; email/username via get-only identifier lookups |
| Client-side pre-validation (amount > 0, balance, same wallet/currency) | EXISTING | `transfer_validator.dart` + `RequestTransferUseCase` |
| Status observation (pending → completed/failed) with 15s timeout | EXISTING | `observe_transfer_status_usecase`; stream errors surface as failures |
| Risk metadata surfaced to user (ENFORCE reasons) | EXISTING | `transfer_cubit._waitForBackendResult` extracts `reasons` |
| Confirmation sheet (amount + recipient) | EXISTING | `transfer_confirmation_dialog.dart`, keyboard-aware |
| Receipt / success screen | MISSING | Success = snackbar + redirect to wallet only |
| Retry a failed transfer | MISSING | Failure is terminal in UI |

### Transactions

| Feature | Status | Evidence / notes |
| --- | --- | --- |
| Paginated history (20/page, cursor) | EXISTING | `startAfter` cursor in repository |
| Load-more | EXISTING | Explicit "Load More" button (not scroll-threshold) |
| Type filter (All / Income / Expense) | EXISTING | `transaction_filters.dart` |
| Status filter (pending/failed) | PARTIAL | `WalletCubit.setFilterStatus` + filter logic exist; **no UI calls it** |
| Date-range filter / text search | MISSING | No search anywhere in the app |
| Transaction detail screen | MISSING | `TransactionTile.onTap` is never passed; no detail route |
| Export (CSV/PDF statements) | MISSING | — |

### Payment requests

| Feature | Status | Evidence / notes |
| --- | --- | --- |
| Create request (resolver for email/username, currency = requester's wallet) | EXISTING | `PaymentRequestCubit.createRequest` |
| Incoming/outgoing streams with accept/decline | EXISTING | `acceptPaymentRequest`/`declinePaymentRequest` callables (atomic accept→transfer) |
| Optimistic accept removal in UI | EXISTING | `acceptRequest` in cubit |
| Backend validation (amount > 0, no self-request) | EXISTING | `onPaymentRequestCreated` marks invalid |
| Payment-request push notification | EXISTING (needs deploy) | `notifyOnPaymentRequest` now exported; was previously dead |
| Request expiry | MISSING | Requests stay PENDING forever |

### Contacts / recipients

| Feature | Status | Evidence / notes |
| --- | --- | --- |
| Add contact by email or @username (backend callable, self-add rejected) | EXISTING | `contacts.ts` |
| Remove contact | EXISTING | Direct Firestore delete, owner-only rules |
| Edit/rename contact | MISSING | — |
| Pick-mode (contact → transfer/request prefill) | EXISTING | `isPickMode` flow |
| Contact actions (send/request shortcuts) | EXISTING | `contact_item.dart` popup menu |
| Contacts search | MISSING | — |

### Notifications

| Feature | Status | Evidence / notes |
| --- | --- | --- |
| FCM token lifecycle (save on login/refresh, delete on logout) | EXISTING | `fcm_token_manager.dart` |
| Push for transfer completed/failed, payment request created/accepted | EXISTING | `notifications.ts`; preference-gated server-side (fail-open on read error) |
| In-app notification center (list, tap = mark read, confirm-swipe delete) | EXISTING | `notifications_page`, `notification_tile` |
| Notification preferences (incoming/outgoing toggles) | EXISTING | Optimistic cubit + backend `shouldSendNotification` gate |
| Unread badge on wallet bell | MISSING | `AppIconButton` supports a `badge` param; nothing feeds it |
| Tapping a notification navigates to its subject | PARTIAL | Always routes to `/wallet`; no payload-based deep link |
| Rich local display of foreground pushes | EXISTING | `local_notification_service` (v22 API) |

### Fraud / risk / limits

| Feature | Status | Evidence / notes |
| --- | --- | --- |
| Risk scoring (amount thresholds, 1h/24h velocity, failure rate) | EXISTING | `fraud.ts`, Remote-Config-tunable, ENFORCE/MONITOR modes |
| Rate limit (10 transfers/min/sender) | EXISTING | `rate_limiter.ts` on `transaction.created` events (count-then-act) |
| Risk review queue records | EXISTING | `risk_reviews` collection (default-deny rules) |
| Admin/manual review UI | MISSING | Reviews are written, nothing consumes them |
| User-facing configurable limits | MISSING | Fraud thresholds only; no per-user limit concept |

### Reconciliation / audit

| Feature | Status | Evidence / notes |
| --- | --- | --- |
| Deterministic double-entry ledger entries (DR/CR) per transfer | EXISTING | `ledger.ts`, Eventarc-driven, idempotent, partial-state repair |
| Scheduled reconciliation (read-only) | EXISTING | `reconcileWallets` daily; logs discrepancies |
| Admin-triggered reconciliation (admin-claimed, token-verified) | EXISTING | `triggerReconciliationNow` |
| Per-transfer connectivity check (ledger + mirrored transactions) | EXISTING | `consistency.ts` — **log-only**, writes no alert records |
| Event replay tooling | EXISTING | `admin_jobs` REPLAY_TRANSACTION_EVENTS job |
| Discrepancy alerting (email/PagerDuty/etc.) | MISSING | Logs only |

### Backend capabilities

| Feature | Status | Evidence / notes |
| --- | --- | --- |
| Money representation: integer minor units everywhere + idempotent admin migration | EXISTING | `utils/money.ts`, `money_migration.ts`, `docs/MONEY_MIGRATION.md` (deployment of migration still pending — ops task) |
| Firestore rules: owner-only wallets, get-only identifiers, deny-by-default audit collections | EXISTING | `firestore.rules` |
| Storage/RTDB locked | EXISTING | `storage.rules`, `database.rules.json` |
| App Check (Play Integrity/App Attest; debug in dev) | EXISTING (client) | Console enforcement toggle is an ops task |
| BigQuery streaming (transfers + ledger) | PARTIAL | Per-row inserts, errors deliberately swallowed (rows can be lost) |
| Eventarc publishing | PARTIAL | No retry — failed publishes are dropped (manual replay job exists) |
| Admin jobs (`admin_jobs` collection trigger) | PARTIAL | 2 job types; no input validation; no writer UI |

### Non-functional

| Feature | Status | Evidence / notes |
| --- | --- | --- |
| Clean Architecture + DI + flavor entries (dev/prod) | EXISTING | Feature-first, injectable/get_it, `main_dev`/`main_prod` |
| Analytics | PARTIAL (stub) | `AnalyticsService` is a debug-print stub with a TODO; **`firebase_analytics` dependency is installed but never imported**; `logTransferSuccess` has zero call sites |
| Crash/performance monitoring | MISSING | No Crashlytics/Sentry/Performance; no `runZonedGuarded`/`FlutterError.onError` — release-mode errors vanish |
| Localization | PARTIAL | 107-key `app_en.arb` covering the widget layer; Arabic absent (notable: wallets are EGP); cubit failure messages mirror backend English strings |
| Accessibility | PARTIAL | Tooltips, 48dp targets, text-scale clamp, contrast fixes done; no screen-reader audit; some GestureDetector-only controls remain |
| Responsive/adaptive | EXISTING | `StatefulShellRoute` + NavigationBar/NavigationRail, clamped text scaling |
| Performance testing | EXISTING | `integration_test/performance` suite (cold start, per-page frame timings, stress scroll) |
| CI | EXISTING | GitHub Actions: format/analyze/test (Flutter 3.41.6 pinned) + Functions tsc/jest |
| Error handling | EXISTING | `Failure` hierarchy implements Exception; repository-mapped; UI shows messages (English only) |
| Offline transaction retry / queueing | MISSING | Transfers require connectivity |

---

## 2. Current User Journeys (as implemented)

1. **Onboard**: Register (email/password) → wallet auto-provisioned → profile setup (unique username) → wallet dashboard. *Works end-to-end.*
2. **Check balance**: Wallet tab → live balance card + recent activity. *Works.*
3. **Send money**: Send tab → recipient (ID/alias/email/@username or pick contact) → amount → confirm sheet → backend executes ≤15s → success snackbar → wallet. *Works; dead-ends without a receipt.*
4. **Request money**: Requests → create (contact or identifier) → requester's currency auto-applied → recipient gets push + sees it in "Incoming" → accept (creates a real transfer) or decline. *Works.*
5. **Manage contacts**: Contacts → add by email/@username → contextual send/request shortcuts. *Works; no search/edit.*
6. **Stay informed**: Push notifications + in-app center with read/delete; notification preferences. *Works; no unread badge or deep linking.*
7. **Personalize**: Theme (system/light/dark, persisted) → profile settings. *Works.*
8. **Leave**: Delete account with zero-balance/no-history guard. *Works.*
9. **Recover from failure**: Failed transfers/requests surface backend reasons (incl. risk-block reasons). *Partial — no retry or help path.*

**Broken/dead-end journeys**: none currently — but there are **truncated** ones: transfer success (no receipt), failed transfer (no retry), notification tap (no routing), failed first-load of contacts (shows empty state).

---

## 3. Feature Gaps (summary of what's missing)

1. **Observability**: analytics is a stub, no crash reporting, no uncaught-error handling — we are blind in production. *(Highest-leverage gap.)*
2. **Transaction depth**: no detail view, no receipt, no search, no date filter, no export.
3. **Notification affordances**: no unread badge, no subject-based navigation.
4. **Lifecycle management**: no payment-request expiry, no transfer retry, no password reset, no email verification, no session management.
5. **Trust surfaces**: no user-facing limits, no help/support entry point, no fees transparency (no fees exist at all).
6. **Money-in/money-out**: wallet-to-wallet only — no cash-in/out rails (deliberate MVP boundary).

---

## 4. UX/UI Improvements

Each item: What → Why → Value → Status → Backend → Flutter → Dependencies → Complexity → Priority.

### 4.1 Transaction detail screen
- **What**: Tap a transaction → detail page (amount, direction, counterparty, status timeline, transfer ID w/ copy, timestamp, note/description).
- **Why**: The single most-expected action in any wallet; today taps do nothing.
- **Value**: High user trust; support deflection ("where did my money go?").
- **Status**: MISSING (data already local — entity has everything).
- **Backend**: none. **Flutter**: new route + page; wire `TransactionTile.onTap` in `transaction_list.dart`.
- **Dependencies**: none. **Complexity**: S. **Priority**: **P1**.

### 4.2 Transfer receipt screen
- **What**: On completion, replace snackbar with a receipt (checkmark, amount, recipient, timestamp, "Done"/"Share").
- **Why**: Confirmation is the emotional payoff of a payment; a snackbar under-communicates.
- **Value**: Perceived reliability; shareable proof.
- **Status**: MISSING. **Backend**: none (transfer doc has all fields). **Flutter**: new page reusing `TransferState.completedTransfer`.
- **Dependencies**: none. **Complexity**: S–M. **Priority**: **P1**.

### 4.3 Unread notification badge
- **What**: Feed `unreadCount` into the existing `AppIconButton.badge` on the wallet bell; auto-clear on viewing the center.
- **Why**: `AppIconButton` already supports badges; notifications exist but are invisible from the hub.
- **Value**: Re-engagement; standard expectation.
- **Status**: IMPROVEMENT (mark-as-read exists; count missing).
- **Backend**: optional `read` flag already implied by status field — client can count locally from the stream. **Flutter**: count in `NotificationsCubit`, badge in `wallet_app_bar.dart`.
- **Dependencies**: none. **Complexity**: S. **Priority**: **P1**.

### 4.4 Notification deep-linking
- **What**: Route by payload (transaction → detail; payment request → requests tab) instead of always `/wallet`; use the (currently dead) `pendingRoute` concept properly.
- **Why**: Notifications that land you somewhere irrelevant feel broken.
- **Value**: Completes the notification loop. **Status**: IMPROVEMENT (`_navigateFromData` hardcodes `/wallet`).
- **Backend**: include `route`/ids in push payloads (`notifications.ts` already has them). **Flutter**: payload switch in `notification_service.dart`.
- **Dependencies**: 4.1 for transaction targets. **Complexity**: M. **Priority**: **P2**.

### 4.5 Status filter UI + failed-transactions view
- **What**: Add a status pill row (or filter sheet); enable the orphaned `setFilterStatus`.
- **Why**: Backend already models `failed`/`pending`; users cannot find failed activity today.
- **Value**: Dispute/complaint first response. **Status**: IMPROVEMENT (logic exists, UI absent).
- **Backend**: none. **Flutter**: `transaction_filters.dart` + cubit wiring. **Dependencies**: none. **Complexity**: S. **Priority**: **P2**.

### 4.6 Infinite scroll for transactions
- **What**: Replace the "Load More" button with scroll-threshold fetching (keep button as fallback).
- **Why**: Standard pattern; button interrupts browsing.
- **Value**: Polish. **Status**: IMPROVEMENT. **Backend**: none. **Flutter**: scroll listener in `transaction_list.dart`.
- **Complexity**: S. **Priority**: **P3**.

### 4.7 Offline staleness banner
- **What**: Timestamp cached data; when serving fallback, show "Showing offline data from …".
- **Why**: Today stale data is indistinguishable from live data — dangerous for a wallet.
- **Value**: Trust; prevents misinformed sends. **Status**: IMPROVEMENT (cache exists, no freshness signal).
- **Backend**: none. **Flutter**: cache wrapper + banner in `wallet_page`. **Complexity**: M. **Priority**: **P2**.

### 4.8 Pull-to-refresh
- **What**: Standard `RefreshIndicator` on wallet/transactions/notifications.
- **Why**: Streams self-update, but explicit refresh is a trust behavior. **Value**: Reassurance.
- **Status**: MISSING. **Complexity**: S. **Priority**: **P3**.

### 4.9 Contact search + rename
- **What**: Search field on contacts; rename a contact (local alias).
- **Why**: Lists grow; aliases aid recognition (emails aren't names). **Status**: MISSING.
- **Backend**: rename needs a `name` field on contact docs (or client-side overlay doc). **Flutter**: search bar + edit dialog. **Complexity**: M. **Priority**: **P3**.

### 4.10 Onboarding polish
- **What**: Welcome carousel + post-registration success state; empty-state illustrations.
- **Why**: First-run is currently purely functional. **Value**: Activation/retention. **Status**: MISSING.
- **Complexity**: M. **Priority**: **P3**.

---

## 5. FinTech / Product Improvements

### 5.1 Failed-transfer retry
- **What**: "Try again" on failed transfers (reuses the idempotent uuid path — safe by design).
- **Why**: Failures happen (timeouts, risk blocks after remediation); today the only path is retyping everything.
- **Value**: Conversion on failed payments. **Status**: MISSING (idempotency already makes it safe).
- **Backend**: none. **Flutter**: keep failed intent in state; button on error + transaction detail.
- **Dependencies**: 4.1. **Complexity**: S–M. **Priority**: **P2**.

### 5.2 Payment-request expiry
- **What**: Auto-expire requests after N days (status `EXPIRED`), enforced by scheduled function.
- **Why**: PENDING-forever requests are a liability and clutter accept flows.
- **Value**: Hygiene; fraud reduction. **Status**: MISSING. **Backend**: scheduled sweep + status check in `acceptPaymentRequest`. **Flutter**: show expiry. **Complexity**: M. **Priority**: **P2**.

### 5.3 User-facing transaction limits
- **What**: Show the user their applicable limits (single-amount, daily) and remaining headroom; surface when risk blocks.
- **Why**: "Transfer blocked by fraud protection" with no context generates support tickets.
- **Value**: Transparency; fewer blocked-transfer surprises. **Status**: MISSING (thresholds exist only in fraud config).
- **Backend**: expose limits via callable/Remote-Config read. **Flutter**: limits card + copy on blocks. **Complexity**: M. **Priority**: **P2**.

### 5.4 Fees framework
- **What**: Optional fee schedule (e.g., % over a threshold) computed server-side at execution; shown pre-send.
- **Why**: Monetization lever; must be transparent before confirmation.
- **Value**: Business revenue. **Status**: MISSING (grep-verified: no fee logic anywhere).
- **Backend**: fee calculation in the movement transaction + fee ledger entries. **Flutter**: fee line in confirmation/receipt.
- **Dependencies**: product decision on pricing. **Complexity**: M–L. **Priority**: **P3** (business call).

### 5.5 Arabic localization + RTL
- **What**: Second locale (ar) with RTL; localizable failure codes.
- **Why**: Currency is EGP — the market is Arabic-speaking; English-only caps reach.
- **Value**: Market fit. **Status**: MISSING (l10n architecture done; only `en` exists; failure messages are backend English).
- **Backend**: error codes on failures (small). **Flutter**: ar ARB + RTL audit. **Complexity**: M–L. **Priority**: **P2** (strategic), sequencing flexible.

### 5.6 Amount-entry improvements
- **What**: Numeric keypad with major-unit formatting, currency symbol prefix, paste-guard.
- **Why**: Money entry is the most error-prone input. **Value**: Fewer mispayments. **Status**: PARTIAL (validated TextField).
- **Complexity**: S. **Priority**: **P3**.

---

## 6. Security Improvements

### 6.1 Wire real analytics without PII (see 7.1) — **P1**
### 6.2 Crash reporting with scrubbing — **P1** (see 7.2)

### 6.3 Password reset + email verification
- **What**: Forgot-password (Firebase reset email) and verify-email gate on sensitive actions.
- **Why**: Account recovery currently does not exist — a forgotten password = lost wallet.
- **Value**: Table-stakes account security. **Status**: MISSING.
- **Backend**: none (Firebase Auth emails; tighten templates). **Flutter**: reset entry on login; verification banner.
- **Complexity**: S–M. **Priority**: **P1**.

### 6.4 App lock (biometric/PIN)
- **What**: Local authentication gate on app resume (local_auth), optional in settings.
- **Why**: Wallets are opened in public; device unlock ≠ app unlock.
- **Value**: Standard wallet expectation. **Status**: MISSING (the dead `enableBiometrics` flag finally gets a consumer or deletion).
- **Backend**: none. **Flutter**: `local_auth` + gate widget + setting. **Complexity**: M. **Priority**: **P2**.

### 6.5 Session/device management
- **What**: List FCM-token-backed devices + Security-Center "sign out everywhere" (delete all token docs + re-auth requirement).
- **Why**: Shared-device and lost-device scenarios. **Status**: MISSING. **Backend**: list/revoke callable. **Flutter**: settings section. **Complexity**: M. **Priority**: **P3**.

### 6.6 Rate-limit hardening
- **What**: Move the 10/min constant to Remote Config; make the count-then-act limiter transactional per sender.
- **Why**: Constant is not tunable without deploy; concurrent sends can exceed it. **Status**: IMPROVEMENT.
- **Complexity**: S. **Priority**: **P3**.

### 6.7 App Check enforcement (ops)
- **What**: Toggle App Check enforcement per Firebase product in console after telemetry review.
- **Status**: PARTIAL (client attestation live; enforcement off). **Complexity**: S (ops). **Priority**: **P2** post-launch.

---

## 7. Backend Improvements

### 7.1 Real analytics pipeline
- **What**: Initialize `FirebaseAnalytics`; implement `AnalyticsService` methods; add the missing `logTransferSuccess` call.
- **Why**: The dependency is already installed but never imported — product decisions are being made blind.
- **Value**: Funnel/retention insight. **Status**: PARTIAL (stub + dead callsites verified).
- **Backend**: none. **Flutter**: service implementation + init in bootstrap. **Complexity**: S. **Priority**: **P1**.

### 7.2 Crash reporting + global error capture
- **What**: FirebaseCrashlytics (or Sentry); `runZonedGuarded` in entry points, `FlutterError.onError`, `ErrorWidget.builder`; scrub PII.
- **Why**: Release-mode errors are currently lost — broken in production = invisible.
- **Value**: Mean-time-to-detect. **Status**: MISSING. **Complexity**: S. **Priority**: **P1**.

### 7.3 Event publishing reliability
- **What**: Add retry policy to `onEventCreated` (or outbox pattern with attempt counter + scheduled sweeper); alert on poison events.
- **Why**: Failed publishes are silently dropped today; downstream ledger/BigQuery lose rows. **Status**: IMPROVEMENT (replay job exists as manual patch).
- **Complexity**: M. **Priority**: **P2**.

### 7.4 Reconciliation alerting
- **What**: `reconcileWallets` writes discrepancy docs to an ops collection + notifies on mismatch instead of log-only.
- **Why**: A ledger product must *know* when books disagree, not hope someone reads logs. **Status**: IMPROVEMENT.
- **Complexity**: S–M. **Priority**: **P2**.

### 7.5 BigQuery ingestion hardening
- **What**: Batched inserts + dead-letter for failed rows (errors are swallowed today).
- **Why**: Analytics completeness. **Status**: IMPROVEMENT. **Complexity**: S–M. **Priority**: **P3**.

### 7.6 Admin jobs validation + console
- **What**: Schema-validate `admin_jobs` input; add an (admin-claim-gated) callable to enqueue jobs; track `risk_reviews` resolution.
- **Why**: Ops safety — malformed job docs fail silently today. **Status**: IMPROVEMENT. **Complexity**: M. **Priority**: **P3**.

### 7.7 Notification preference consistency
- **What**: `shouldSendNotification` fails open on read errors — flip to fail-closed for non-critical pushes or add alerting.
- **Status**: IMPROVEMENT. **Complexity**: S. **Priority**: **P3**.

---

## 8. New Feature Ideas

| Feature | What | Why/Value | Complexity | Priority |
| --- | --- | --- | --- | --- |
| **QR pay-me code** | Personal QR encoding username; scan-to-pay fills recipient | Removes identifier typing; top wallet growth loop | M | **P3→P2** post-launch |
| **Activity export (CSV/PDF statement)** | Date-ranged statement generation | Trust + accounting needs | M | P3 |
| **Spending insights** | Monthly in/out summary from existing transaction data | Engagement; cheap (data exists) | M | P3 |
| **Favorite/recent recipients** | Recipient shortcuts on send sheet | Faster sends; uses existing transfer history | S–M | **P2** |
| **In-app help & support** | FAQ + contact channel + "report a problem" (prefilled diagnostics) | Trust; ties into crash reporting | S–M | **P2** |
| **Scheduled/standing transfers** | Recurring sends | Retention; requires scheduler + cancellations | L | OPTIONAL/FUTURE |
| **Multi-currency wallets + FX** | Second currency + conversion | Market expansion; current design is strictly same-currency | L | OPTIONAL/FUTURE |
| **Bill/merchant payments** | Payee catalog | Business expansion | L | FUTURE |
| **Cash-in/out rails (PSP/card)** | Deposits/withdrawals | Requires licensed PSP integrations, webhooks, compliance | L | FUTURE — compliance-gated |
| **Disputes/refunds workflow** | In-app dispute on a transaction | Regulatory expectation in many markets | M–L | FUTURE |
| **Referral program** | Invite rewards | Growth; fraud-sensitive | M | OPTIONAL |

**OUT OF SCOPE (deliberate)**: card issuing, lending/credit, crypto, merchant acquiring, KYC onboarding (assumes an upstream compliance layer), agent banking. These transform the product class; revisit only with a compliance partner.

---

## 9. Recommended MVP Scope (to call this production-ready)

**Definition**: ship-ready for a closed pilot on the existing single-currency wallet-to-wallet product.

Must-haves (all small, most already scaffolded):

1. Crash reporting + global error capture (7.2) — *P1*
2. Real FirebaseAnalytics wiring (7.1) — *P1*
3. Password reset + email verification (6.3) — *P1*
4. Transaction detail screen (4.1) — *P1*
5. Transfer receipt screen (4.2) — *P1*
6. Unread notification badge (4.3) — *P1*
7. Run the money migration + deploy functions after merge (ops runbook) — *P0 ops*
8. Create separate dev/prod Firebase projects (ops — needs console access) — *P1 ops*

Explicitly **not** in MVP: fees, QR, multi-currency, PSP rails, biometrics (can slip to fast-follow), session management, export.

---

## 10. Future Roadmap

**Now (stabilize & see)**: 7.2, 7.1, 6.3, migration deployment, dev/prod project separation.

**Next (complete the core loops)**: 4.1 transaction detail, 4.2 receipt, 4.3 badge, 4.5 status filters, 5.1 retry, 5.2 request expiry, 6.4 app lock, favorites, help/support, App Check enforcement, rules emulator tests in CI.

**Later (grow)**: QR pay-me, Arabic/RTL, insights, statements, deep-linking v2, event reliability rework, session management, limits transparency.

**Someday (strategic, compliance-dependent)**: fees framework, multi-currency/FX, PSP rails, disputes, scheduled transfers.

---

## 11. Prioritized Backlog

| # | Item | Type | Priority | Complexity | Backend | Flutter |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Run money migration + deploy functions | Ops | **P0** | S | deploy + callable | — |
| 2 | Crash reporting + error capture (7.2) | IMPROVEMENT | **P1** | S | — | bootstrap + dep |
| 3 | Analytics wiring (7.1) | IMPROVEMENT | **P1** | S | — | service impl |
| 4 | Password reset + email verification (6.3) | NEW FEATURE | **P1** | S–M | templates | login/banner |
| 5 | Transaction detail screen (4.1) | NEW FEATURE | **P1** | S | — | route + page |
| 6 | Transfer receipt screen (4.2) | NEW FEATURE | **P1** | S–M | — | page |
| 7 | Unread badge (4.3) | IMPROVEMENT | **P1** | S | — | cubit + bell |
| 8 | Dev/prod Firebase projects | Ops | **P1** | M | console | regen options files |
| 9 | Status filter UI (4.5) | IMPROVEMENT | P2 | S | — | filters |
| 10 | Failed-transfer retry (5.1) | NEW FEATURE | P2 | S–M | — | state + button |
| 11 | Request expiry (5.2) | NEW FEATURE | P2 | M | scheduled fn | labels |
| 12 | Offline staleness banner (4.7) | IMPROVEMENT | P2 | M | — | cache wrapper |
| 13 | Notification deep links (4.4) | IMPROVEMENT | P2 | M | payload | routing |
| 14 | Limits transparency (5.3) | NEW FEATURE | P2 | M | callable | UI |
| 15 | App lock / biometrics (6.4) | NEW FEATURE | P2 | M | — | local_auth |
| 16 | Arabic + RTL (5.5) | NEW FEATURE | P2 | M–L | error codes | ar ARB + audit |
| 17 | App Check enforcement (6.7) | Ops | P2 | S | console | — |
| 18 | Rules emulator tests in CI | IMPROVEMENT | P2 | M | test infra | — |
| 19 | iOS flavor schemes | IMPROVEMENT | P2 | M | — | Xcode |
| 20 | Reconciliation alerting (7.4) | IMPROVEMENT | P2 | S–M | functions | — |
| 21 | Favorite recipients | NEW FEATURE | P2 | S–M | — | send sheet |
| 22 | Help & support | NEW FEATURE | P2 | S–M | — | pages |
| 23 | Event publish retries (7.3) | IMPROVEMENT | P2 | M | functions | — |
| 24 | Infinite scroll (4.6) | IMPROVEMENT | P3 | S | — | list |
| 25 | Pull-to-refresh (4.8) | IMPROVEMENT | P3 | S | — | pages |
| 26 | Contact search/rename (4.9) | NEW FEATURE | P3 | M | optional | UI |
| 27 | BigQuery batching/dead-letter (7.5) | IMPROVEMENT | P3 | S–M | functions | — |
| 28 | Admin jobs validation/console (7.6) | IMPROVEMENT | P3 | M | functions | — |
| 29 | Rate-limit Remote Config (6.6) | IMPROVEMENT | P3 | S | functions | — |
| 30 | Preference fail-closed (7.7) | IMPROVEMENT | P3 | S | functions | — |
| 31 | Amount entry keypad (5.6) | IMPROVEMENT | P3 | S | — | input |
| 32 | Onboarding carousel (4.10) | IMPROVEMENT | P3 | M | — | pages |
| 33 | Session management (6.5) | NEW FEATURE | P3 | M | callable | settings |
| 34 | QR pay-me | NEW FEATURE | P3 | M | — | scanner/QR |
| 35 | Statements/export | NEW FEATURE | P3 | M | optional | UI |
| 36 | Spending insights | NEW FEATURE | P3 | M | — | UI |
| 37 | Fees framework (5.4) | NEW FEATURE | P3 | M–L | txn logic | UI |
| 38 | Scheduled transfers | NEW FEATURE | FUTURE | L | scheduler | UI |
| 39 | Multi-currency + FX | NEW FEATURE | FUTURE | L | FX engine | UI |
| 40 | PSP cash-in/out, disputes | NEW FEATURE | FUTURE | L | PSP webhooks | UI |

---

## Verification notes

Claims corrected by this audit (things a reader might assume from docs but that are NOT true):

- `firebase_analytics` is a dependency but **never initialized or imported**; `AnalyticsService` is a debug-print stub.
- No Crashlytics/Sentry and no global error handlers exist.
- `TransactionTile.onTap` exists but is never wired; there is no transaction detail route.
- `WalletCubit.setFilterStatus` exists with filter logic but has no UI caller.
- `enableBiometrics`/`enableBetaFeatures` flags have zero consumers.
- Notification preferences gate **push sending server-side only**; the in-app list is unfiltered by design.
- The offline cache serves stale-first-page data indefinitely on failure, with no freshness marker.
- BigQuery/event publishing can silently drop rows; the replay admin job is the manual mitigation.
- `logTransferSuccess` is defined with zero call sites.
