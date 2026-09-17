# Boklo Wallet — Modernization Audit & Migration Plan

> Status: **ACTIVE** · Audit date: 2026-09-17 · Baseline commit: `be8d51c`
> Every finding below was verified against the actual code (file:line references included), not against project documentation. Where docs and code disagree, the discrepancy is called out explicitly (§7.9, §K).

## Progress tracker (updated 2026-09-17)

| Phase | Status | Commit(s) |
| --- | --- | --- |
| Audit + this plan | ✅ Done | `7052d79` |
| 1 — Build stabilization (Flutter 3.41.6/Dart 3.11.4, freezed 3, injectable 3, dep majors, dead code, zero analyzer issues) | ✅ Done | `f89a80e`, `cd65ef6` |
| 2 — Client P0s (router auth guard, ledger gate, timestamp integrity, stream errors, legacy transfer path removal) | ✅ Done | `46ff96a` |
| 3 — Dependency rule restored, real TransferState, dead getTransfers chain removed | ✅ Done | `68a8061` |
| 4 — Security hardening (storage/RTDB locked, admin-claim gates, fraud signal fix, currency assertion, notify export, transfer-create validation, doc overclaims corrected) | ✅ Done | `5fb998a` |
| 5 — Money display via intl (MoneyFormatting extension); payment-request currency derived from requester wallet | ✅ Done | `34b138a` |
| 6 — Responsive/adaptive shell + a11y pass | ⏳ Pending | — |
| 7 — l10n extraction (~160 hardcoded strings) | ⏳ Pending | — |
| 8 — Owner-decision items (backend minor units, balance read-split, project separation, iOS flavors, App Check, CI) | 🔒 Blocked on owner | — |
| 9 — Test expansion (payment-request/contacts/notifications cubits, rules tests) | ⏳ Pending | — |

Deviations from the original tables: `dio` and `internet_connection_checker_plus` were **removed** (zero callers) rather than upgraded; the `backendAuthoritativeTransfers` flag was deleted entirely (single idempotent path). The client-side `Money` minor-units type (§G) remains deferred with the backend migration to avoid client/backend format mismatch; intl-based display formatting shipped instead.

---

## A. Executive Summary

Boklo Wallet is a Firebase-backed Flutter digital wallet (auth, wallet provisioning, transfers, payment requests, contacts, notifications) with a **TypeScript Cloud Functions ledger backend**.

The repository is **not** a legacy codebase: it already follows feature-first Clean Architecture (data/domain/presentation per feature), Bloc/Cubit state management, `get_it`+`injectable` DI, `go_router`, freezed/Equatable models, flavor-based entry points (`main_dev`/`main_prod`), generated l10n wiring, a responsive-helper library, and 16 test files including a performance integration-test suite. The Cloud Functions side implements a genuinely backend-authoritative, event-driven, idempotent ledger (deterministic event/ledger IDs, in-transaction re-validation, reconciliation job, fraud scoring, BigQuery streaming).

The real gaps are **correctness and hardening, not structure**:

1. **Monetary values are `double` everywhere** (client and backend) — the single most serious FinTech defect.
2. **No router-level auth guard** — deep links render authenticated pages when logged out.
3. **A debug ledger screen is reachable from the production balance card**, ungated.
4. **Security rules over-expose data**: every wallet's balance is readable by every authenticated user; Cloud Storage is fully open to any authenticated user; two privileged callables lack admin checks.
5. **The committed `pubspec.lock` cannot be installed on the available toolchain** — resolution only succeeds after 9 direct dependencies take major upgrades (notably freezed 2→3).
6. Localization is a template stub (1 key), the responsive library has 0 usages, and ~160 user-facing strings are hardcoded English.

Clean Architecture diagnostic score (per the dependency-rule checklist): **6/10** — domain layers are clean (no Firebase/dio/dart:io imports anywhere in `features/*/domain` except two use cases importing data-layer datasources), use cases are delivery-independent, and Main composes via DI; failures are the two domain→data imports, scattered service-locator use in widgets, and business orchestration living in cubits.

---

## B. Current Stack

| Component | Version (verified) |
| --- | --- |
| Flutter (available in this environment) | **3.41.6 stable** / Dart **3.11.4** (SDK at `~/Abdullah/Work/portfolio-flutter/flutter`; not on PATH) |
| Flutter required by committed lock | dart `>=3.10.0 <4.0.0`, flutter `>=3.35.0` (lock resolved on an older 3.35-era toolchain) |
| State management | bloc 9.2.0 / flutter_bloc 9.1.1 / bloc_test 10.0.0 |
| DI | get_it 9.2.0 + injectable 2.7.1 (+ generator 2.4.0) |
| Routing | go_router 17.0.1 |
| Networking | dio 5.9.0 (**registered in DI but has zero callers** — vestigial) |
| Backend | Firebase Auth 6.x-gen, Cloud Firestore 6.x-gen, Cloud Functions 6.x-gen (Node 22, TypeScript, `firebase-admin 13.6`, `firebase-functions 7.0`), FCM 16.x, Storage 13.x, Analytics 12.x |
| Models | freezed 2.5.8 (17 files) + json_serializable 6 + Equatable (mixed styles) |
| Errors | fpdart 1.2.0 (`Either`), custom `Failure` hierarchy (message-only) |
| Storage | flutter_secure_storage 10.x |
| Lints | very_good_analysis 10.x |
| Tests | flutter_test + mocktail + bloc_test; 16 unit/bloc/data test files; 11 perf integration tests + driver scaffolding |
| CI/CD | **None** (no `.github/`, no Fastlane; `docs/deployment.md` admits manual deploy) |
| Platforms wired | Android flavors ✅ (dev/prod, AGP 8.11.1, Gradle 8.14, Kotlin 2.2.20, compileSdk 36) · iOS **❌** (no Podfile, no flavor configurations/schemes) · Web/Linux enabled in tool config, no checked-in web dir |

---

## C. Current Architecture (how it actually works today)

```text
main_dev.dart / main_prod.dart
  └─ AppBootstrap (core/config)            ← composition root: Firebase init, emulator gate, getIt init,
       └─ di_initializer (@InjectableInit)    awaits AuthCubit.checkAuthStatus(), picks initial route
UI (pages/widgets, ~61 files, no god widgets — max 310 lines)
  └─ Cubits (BaseCubit: freezed BaseState<T>, runBlocCatching, safeEmit)
       └─ UseCases (fpdart Either)           ← 2 violations import data sources directly
            └─ Repositories (domain contracts, data impls map Failure)
                 ├─ Firestore data sources (wallet/transactions watch-only reads)
                 ├─ Cloud Functions callables (provisionWallet, setUserProfile,
                 │   deleteAccount, addContact, accept/declinePaymentRequest)
                 └─ Transfers: client writes transfers/{uuid} inside runTransaction;
                     Cloud Function onTransferCreated executes the ledger movement
                     atomically (re-reads status in-txn → idempotent, race-safe)
```

Verified strengths:

- **Backend authority holds on the client**: no client code path writes balances; wallet/transaction data is read via owner-scoped watches; Firestore rules pin `balance`/`id`/`currency` on wallet updates and deny writes to `users`, `usernames`, `wallets/{id}/transactions`, `wallets/{id}/ledger`, `transfers` updates, global `ledger`/`events` (`firestore.rules:21-23,45,76-79,88,95,121,127,139`).
- **Idempotency (new path)**: transfer IDs are uuid-v4 minted in the domain (`request_transfer_usecase.dart:18,46`), used as Firestore doc IDs; duplicate processing is rejected inside the Functions transaction (`functions/src/transfers.ts:197-200`).
- **Layering discipline**: zero firebase/dio imports in presentation; repositories return `Either`/Failure streams; widget decomposition and design-token adoption are genuinely good.
- **No committed secrets**: no keystores, service accounts, private keys in tree or git history. `google-services.json`/`GoogleService-Info.plist`/`firebase_options_*.dart` contain only public client config.

---

## D. Target Architecture

The existing skeleton is the right target — the plan **hardens it rather than re-architecting it**:

- Keep feature-first data/domain/presentation, BaseState/BaseCubit, use-case-per-operation, `Either`-based repositories, get_it composition root.
- Enforce dependency direction: **no domain file may import from `data/`** (fix the 2 violations via repository methods).
- Router-level auth `redirect` driven by auth state (single source of truth), typed route helpers instead of magic strings.
- A `Money` value type (integer minor units) with intl-based formatting at the presentation edge; wire format to Firestore unchanged in this phase.
- Consolidate dead duplicate systems (theme tokens, bootstrap, network stack) into one canonical implementation each.
- Feature-flag gate for debug-only surfaces (`ledger_debug`), wired and actually consulted.
- Localization via ARB as the only source of user-facing strings; currency/date formatting via intl everywhere.
- Responsive layer promoted from dead code to the standard page scaffold (adaptive shell navigation: `NavigationBar` on phones, `NavigationRail` on wide screens).

---

## E. Architecture Gaps

| Area | Current | Target | Priority |
| --- | --- | --- | --- |
| Money representation | `double` in entities/UI (`wallet_entity.dart:9`, `transaction_entity.dart:20`, `transfer_entity.dart:27`) and JS numbers in Functions | Integer minor units `Money` type client-side; backend conversion planned & gated (needs production-data approval) | **P0** |
| Route authorization | No `redirect`; auth checked once at bootstrap (`app_bootstrap.dart:52-65`) | go_router `redirect` listening to auth state; deep-link safe | **P0** |
| Debug surface | `/ledger` route unconditional (`app_router.dart:70-73`), opened by balance card tap (`balance_card.dart:37`) | Feature-flag-gated; removed from production navigation | **P0** |
| Domain purity | `provision_wallet_usecase.dart:2`, `set_user_profile_usecase.dart:3` import data sources | Route through `WalletRepository` / `AuthRepository` | P1 |
| Transfer state | `TransferState` has zero fields (signal-only, `transfer_state.dart:3-8`) | Freezed state with phase/amount/failure data | P1 |
| Timestamp integrity | `TimestampConverter.fromJson` falls back to `DateTime.now()` (`json_converters.dart:16`) | Fail loudly / nullable, never fabricate financial timestamps | P1 |
| Stream error handling | `Stream.handleError` return discarded → status stream dies silently (`transfer_repository_impl.dart:94-97`) | `asyncMap` + `Left(Failure)` emission | P1 |
| Dead network stack | Dio + `auth_interceptor` (`dummy_token`, `auth_interceptor.dart:19`) + `retry_executor` + `response_wrapper` unused | Remove or implement; no half-built transport in a fintech app | P1 |
| Bootstrap | Dead duplicate `core/bootstrap/app_bootstrap.dart` (doesn't compile, `:25`); auth resolved twice at startup | Delete dead file; single auth resolution feeding both cubit and router | P1 |
| Cubit orchestration | Provision fallback timers, merge/sort/filter in `wallet_cubit.dart:66-144,239-246`; end-to-end transfer flow in `transfer_cubit.dart:38-130` | Extract to domain services/use cases | P2 |
| Service locator | 52 `getIt<>()` sites inside widgets | Constructor injection for cubits; context extensions for services | P2 |
| Notification routing | `_navigateFromData` always pushes `/wallet`; `pendingRoute` written, never read (`notification_service.dart:87-94`) | Payload-driven typed routes | P2 |
| State model consistency | Mixed freezed (16 files) vs hand-written Equatable (`transfer_entity.dart`) | Uniform freezed | P3 |

---

## F. Dependency Migration

Verified against the environment toolchain (Flutter 3.41.6 / Dart 3.11.4). `flutter pub upgrade --major-versions` resolves cleanly with these 9 constraint changes (dry-run: 115 packages refreshed).

| Package | Current | Target/Action | Reason | Priority |
| --- | --- | --- | --- | --- |
| freezed / freezed_annotation | 2.5.8 | **→ ^3.2.5 / ^3.1.0** | freezed 2 is unresolvable on Dart 3.11 test toolchain; 3.x is current (17 files to migrate) | **P0** |
| injectable / injectable_generator | 2.7.1 / 2.4.0 | **→ ^3.0.0 / ^3.0.2** | required for current build/source_gen chain | P0 |
| flutter_secure_storage | 10.0.0 | **→ ^11.2.0** | current major; Android storage backend updates | P0 |
| equatable | 2.0.7 | **→ ^3.0.0** | align with current SDK | P0 |
| flutter_local_notifications | 19.5.0 | **→ ^22.3.1** | current major (API surface changed — verify init code) | P0 |
| internet_connection_checker_plus | 2.9.1 | **→ ^3.1.2** | current major (verify `network_info.dart` API) | P0 |
| device_info_plus | 12.3.0 | **→ ^13.2.0** | current major | P0 |
| Firebase suite (core/auth/firestore/functions/messaging/storage/analytics) | 6.1–16.1 pins | **→ latest resolving** (4.15/6.7/6.10/6.5/16.7/13.6/12.6) | patch/minor refresh within majors | P1 |
| flutter_driver (dev) | sdk dep | **REMOVE** | zero imports anywhere; deprecated scaffolding | P1 |
| fpdart | 1.2.0 | KEEP | load-bearing (`Either` in all use cases/repositories) | — |
| dio | 5.9 | **REMOVE with its interceptor/response_wrapper/retry stack** (or resurrect only when a REST API exists) | zero callers; `dummy_token` interceptor is security noise | P1 |
| bloc / flutter_bloc / bloc_test | 9.x / 10.x | KEEP | current | — |
| go_router | 17.x | KEEP | current | — |
| very_good_analysis | 10.x | KEEP (10.2.0 resolving) | current | — |
| uuid, google_fonts, intl, cupertino_icons, mocktail, build_runner, json_serializable | current | KEEP / patch-refresh | in active use | — |
| connectivity_plus (transitive) | dropped by resolver | — | only used by replaced checker major | — |

---

## G. FinTech Risk Audit

| Area | Finding | Risk | Recommendation | Priority |
| --- | --- | --- | --- | --- |
| Money type | Balances/amounts are IEEE-754 doubles end-to-end; summation in `ledger_cubit`; display via `toStringAsFixed(2)` (6 sites) | Rounding drift in a **financial ledger**; `0.1+0.2` class bugs | Client: integer minor-units `Money` + intl formatting. Backend: migrate `balance`/`amount` to integer minor units in Functions + Firestore (production-data migration — **requires explicit approval**, documented as Phase 8 gate) | **P0** |
| Currency handling | `onTransferCreated` moves `amount` 1:1 with **no currency validation** between wallets (`functions/src/transfers.ts:214-224`); client hardcodes `'USD'` in one form (`create_payment_request_form.dart:37`) while all wallets seed `"EGP"` | Cross-currency value corruption when multi-currency arrives | Add currency equality assertion in the Functions transaction now | **P1** |
| Fraud signal dead | `fraud.ts:236` queries `status == 'FAILED'` but writes use `'failed'` (`transfers.ts:309`) → failure-rate signal always 0 | Fraud model missing its negative signal; silent | Fix constant; add a Functions unit test | **P1** |
| Fraud fails open | Fraud-check errors log *"failing open"* and allow the transfer (`transfers.ts:179`) | Risk controls bypassed exactly when they're needed | Fail closed for BLOCK-threshold amounts, alert on error | P1 |
| Privileged callable | `migrateWalletIdentifiers` checks only `request.auth` (`functions/src/migration.ts:16-19`); its own comment admits an admin check is missing; dumps all user emails into world-readable `wallet_identifiers` | Mass PII exposure triggerable by any authenticated user | Require `admin` custom claim | **P1** |
| Reconciliation endpoint | `triggerReconciliationNow` is `onRequest` with no in-code auth (`reconciliation.ts:146-160`); `scripts/test_reconciliation.sh` calls it tokenless | Cost/DoS + internal stats exposure | Require auth/IAM or convert to schedule-only | P1 |
| Balance privacy | `firestore.rules:65`: every wallet doc (incl. `balance`, `ownerEmail`) readable by **every** authenticated user; `users` profiles world-readable (`:16`); `wallet_identifiers` lists all emails (`:132-134`) | Complete financial-privacy and user-directory leak | Split public profile fields into a functions-written `wallet_public` doc; wallet reads owner-only; keep discovery on identifiers + public docs | **P1** |
| Storage | `storage.rules:8-10`: entire bucket read+write for any authenticated user | Any user can overwrite/delete any object; arbitrary uploads | Scope to `users/{uid}/...` with owner rules + size/type limits | **P1** |
| RTDB | `database.rules.json`: full read/write for any authenticated user; app has no RTDB dependency | Open database deployed via `firebase.json` | Set `".read": false, ".write": false` | P2 |
| Legacy transfer path | Feature flag `backendAuthoritativeTransfers=false` default enables timestamp-ID transfers with no idempotency (`transfer_cubit.dart:113`) | Duplicate transfer records on retry | Delete the legacy path; make the uuid path the only path | P1 |
| Client "rate limit" | 2s in-memory throttle in `transfer_cubit.dart:35-36` | Resets per instance; cosmetic only | Server-side is the real limit (10/min in `rate_limiter.ts`) — remove client pretense or persist it | P3 |
| Timestamp fabrication | `DateTime.now()` fallback for unparseable timestamps (`json_converters.dart:16`) | Forged financial timestamps on malformed data | Throw → mapped Failure | P1 |
| Notification gap | `notifyOnPaymentRequest` defined but **not exported** (`functions/src/index.ts:23`) → payment-request notifications never fire | Users never notified for payment requests (functional, not financial) | Export + deploy | P2 |

---

## H. Responsive UI Audit

The responsive library (`lib/shared/responsive/`) is well-designed and **completely unused**: `ResponsiveBuilder` has 0 usages; `ResponsiveConstraint` is used once (600px cap in `app_page_scaffold.dart:48`). Every page is a phone-column at any window size; there is no bottom navigation and no `NavigationRail` — no persistent navigation at all.

| Area | Problem | Recommendation | Priority |
| --- | --- | --- | --- |
| Adaptive navigation | Flat 12-route list, hub-and-spoke via wallet AppBar | `StatefulShellRoute` + `NavigationBar` (compact) / `NavigationRail` (medium+` tablet/wide` | P1 |
| Layout adaptation | 0 pages use `ResponsiveBuilder`; hardcoded caps 600/440 (`login_page.dart:48-50`) | Standardize on the existing responsive primitives in `AppPageScaffold`; two-pane wallet on wide | P1 |
| Dark-mode contrast | Light-only `textSecondaryLight` used unconditionally (`summary_item.dart:31`, `payment_request_status_chip.dart`) — dark-gray-on-dark in dark mode | Theme-aware color resolution | P1 |
| Money display | `toStringAsFixed(2)` (6 sites) + raw double interpolation (`payment_request_item.dart:42`, `transfer_confirmation_dialog.dart:79`) | `NumberFormat.simpleCurrency/decimalPattern` via Money type | P1 |
| Payment requests page | No loading state, no error state — failures render as "No requests" (`payment_request_list_page.dart:37-95`) | Full loading/error/empty triad like wallet page | P1 |
| Accessibility | 0 tooltips, 0 `Semantics`; IconButtons unlabeled; touch targets 32–44dp (`app_icon_button.dart:10,40`, `transaction_filters.dart:103-107`); labels not associated with fields (`app_text_field.dart:44-48`); no text-scale handling (`app_button.dart:58` fixed 52dp) | Tooltips + semantics pass; 48dp minimums; `labelText`; min-height + scrollable content | P1 |
| Keyboard/sheets | Confirmation sheet lacks `viewInsets` padding (`transfer_confirmation_dialog.dart:28-31`); delete dialog fixed `width: 420`, non-scrollable, autofocus field (`delete_account_dialog.dart:48`) | Follow `add_contact_sheet.dart:41` pattern; scrollable dialog content | P2 |
| Destructive UX | `Dismissible` deletes notifications with no confirm/undo (`notification_tile.dart:38-52`) | `confirmDismiss` or snackbar-undo | P2 |
| Text scale | No `textScaler` handling app-wide; `app.dart:35-37` builder is a no-op | Clamp/verify at extreme scales; fix fixed-height text containers | P2 |
| Hygiene | 7 raw `fontSize:` literals in 5 files; 2 raw `Color(0x...)` + 5 `Colors.green/red` outside theme; `findAncestorWidgetOfExactType` hack (`transfer_page.dart:42`) | Token-only colors/typography; pass data via route extra/constructor | P2 |

Positives verified: only 7 fontSize literals and 1 fixed >100 height in the whole app; SafeArea coverage good; keyboard scroll correct on all forms; locale-aware primary date formatting (`DateFormat.yMMMd().add_jm()`); loading/empty/error triads complete on wallet, transfers, notifications, profile, notification settings.

---

## I. Security Audit

**Verified clean:** no secrets, keystores, service-account JSONs, or private keys in tree or git history (`git log --all --diff-filter=A` checked); Android permissions least-privilege (`INTERNET`, `POST_NOTIFICATIONS` only, `AD_ID` removed); release manifest enforces ATS defaults; no cleartext exceptions in release.

Findings (secrets redacted; Firebase web API keys are public-by-design and not treated as secrets):

| Area | Finding | Risk | Recommendation |
| --- | --- | --- | --- |
| Firestore | Balance/profile/directory exposure — see §G rows above | Financial privacy | Rules + data-split per §G |
| Storage | Bucket fully open to authenticated users (`storage.rules:8-10`) | Data tampering | Path-scoped owner rules |
| Callables | `migrateWalletIdentifiers` no admin check; `triggerReconciliationNow` no auth | PII mass export; cost/DoS | Claims/auth gating |
| App Check | **README/docs claim App Check (Play Integrity/App Attest) is active — it is not**: no `firebase_app_check` dependency, no init code (README:41,97; SOURCE_OF_TRUTH.md §10) | Docs promise a control that doesn't exist | Either implement App Check or correct all docs (done in §K pass) |
| Docs vs rules | README:40 claims "users only access their own data" — contradicted by `firestore.rules:16,65,133` | False assurance | Correct docs with the rules fixes |
| Debug leakage | `dummy_token` Bearer in `auth_interceptor.dart:19`; `print()` logging (`logger_interceptor.dart:35,46,56`); emulator config ships in prod builds (gated, acceptable) | Confusion/noise; log hygiene | Delete dead stack; structured logger, kDebugMode-gated |
| Android signing | `key.properties` correctly gitignored and absent; no keystore committed ✅ | — | Document release-signing setup |
| iOS | No usage-description strings yet (none currently required); `RunnerTests` bundle id still `com.example.boklo.RunnerTests` (`project.pbxproj:383`) | Store submission friction | Fix at iOS wiring time |

---

## J. Testing Gaps

Existing (verified): 16 unit/bloc/data test files covering auth use cases/cubit/repository, transfer validator/use case/datasource/repository/cubit, wallet cubit, discovery, delete-account dialog, username validator; 11 performance integration tests; test_driver scaffolding.

Missing, in priority order:

1. **Payment-request cubit** — zero tests for a feature that mutates money via `acceptPaymentRequest`.
2. **Contacts / notifications / notification-preferences cubits** — untested.
3. **Auth redirect logic** — the new router guard (Phase 3) needs bloc-level redirect tests (logged-out → `/login`, logged-in → `/wallet`).
4. **Money type** — rounding/formatting/parsing property tests once introduced.
5. **TimestampConverter** — reject/fail cases (currently fabricates dates).
6. **Firestore rules tests** — emulator-based rules unit tests for the ownership matrix (owner vs other user vs unauthenticated × read/write per collection). Blocked in this environment unless `firebase-tools` is available; documented as follow-up with exact test matrix.
7. **Functions tests** — at minimum for the fixed fraud-status constant and the currency-assertion in `onTransferCreated`.
8. **Dead duplicate** — `test/features/wallet/presentation/cubit/wallet_cubit_test.dart` duplicates the `bloc/` test for a path that doesn't exist; delete the `cubit/` copy.

Do not chase coverage %; the target is: every money-mutating flow and the auth gate have passing tests before "done".

---

## K. Technical Debt (ranked by impact)

1. **P0 — Stale dependency lock**: committed lock unresolvable on available stable toolchain; blocks build, analyze, and test (verified: `flutter pub get` version-solving failure: freezed 2.x analyzer constraint vs Dart 3.11 flutter_test).
2. **P0 — double money** (§G).
3. **P0 — No auth guard** (§E).
4. **P0 — Ungated `/ledger`** (§E).
5. **P1 — Dead systems**: `core/bootstrap/app_bootstrap.dart` (won't compile), dio network stack (`api_client`, `auth_interceptor`, `response_wrapper`, `retry_executor` — 0 callers), `shared/theme/` tokens (0 imports, **conflicting values** with live `config/theme`), `core/repository/{repository_helper,sync_policy}.dart`, `core/utils/{constants,username_validator}.dart` (+ its test), `features/wallet/.../transaction_item.dart` (superseded by shared `TransactionTile`), `shared/widgets/atoms/app_text.dart`, `app_button` dual API (`isSecondary` + `variant`), `getTransfers()` stub returning `[]` (`transfer_remote_data_source.dart:50-53`).
6. **P1 — Legacy transfer path** behind default-off flag (§G).
7. **P1 — l10n stub**: single template ARB key (`counterAppBarTitle`); ~160 hardcoded English strings across 42 files; failure messages hardcoded in `failures.dart`.
8. **P2 — Stale docs**: ARCHITECTURE.md references removed `main_common.dart`; docs/architecture.md describes a `Transaction` doc + `onTransactionCreated` (actual: `transfers` + `onTransferCreated`) and claims reconciliation auto-fixes balances (code says READ-ONLY, `reconciliation.ts:12-13`); docs/cloud_functions.md lists an unexported function and omits five real ones; REFACTORING_PLAN.md is a generic template unrelated to this repo; App Check claims false.
9. **P2 — Mixed model styles, empty TransferState, in-cubit orchestration, service-locator scattering** (§E).
10. **P3 — Hygiene**: `print()` logging, magic-string routes, no-op `app.dart` builder, empty `ThemeConfig` stub, notification tile 24h-only time format, `fontSize`/raw-Color literals.

---

## L. Migration Phases

Ordered; each phase ends with format → analyze → test → review → commit.

### Phase 1 — Build stabilization on current stable (this environment)
- **Objective**: `flutter pub get && analyze && test` all green on Flutter 3.41.6.
- **Work**: `pub upgrade --major-versions` (9 constraint changes, §F); remove `flutter_driver`; migrate 17 freezed files to freezed 3 syntax; adjust `injectable` 3 / `flutter_secure_storage` 11 / `flutter_local_notifications` 22 / `internet_connection_checker_plus` 3 API changes; regenerate codegen.
- **Files**: `pubspec.yaml`, all freezed-annotated files, `secure_storage_service.dart`, `local_notification_service.dart`, `network_info.dart`, DI init.
- **Dependencies**: none. **Risk**: medium (freezed 3 breaking changes are mechanical).
- **Outcome**: reproducible modern build. **Verification**: full `flutter analyze` (very_good_analysis) + `flutter test` pass.

### Phase 2 — P0 correctness (client)
- **Objective**: close the three client P0s + two data-integrity P1s.
- **Work**: go_router auth `redirect` driven by auth stream; gate `/ledger` behind feature flag and remove balance-card tap navigation; fix `TimestampConverter` fallback; fix swallowed stream error in `transfer_repository_impl`; delete legacy timestamp-ID transfer path.
- **Verification**: new tests for redirect + converter; existing suite green.

### Phase 3 — Architecture debt
- **Objective**: dependency rule restored; dead systems removed.
- **Work**: fix 2 domain→data imports via repositories; delete dead files (§K.5 list); real `TransferState`; move wallet merge/sort + provision fallback into domain services; constructor-inject cubits into widgets where practical.
- **Verification**: grep-clean domain imports; analyze + tests.

### Phase 4 — Security hardening (rules + functions)
- **Objective**: close §G/§I findings that don't require production-data migration.
- **Work**: storage path-scoping; RTDB off; admin-claim gates on `migrateWalletIdentifiers` + reconciliation endpoint; fraud status-constant fix + currency assertion in transfer txn; export `notifyOnPaymentRequest`; correct App Check docs or defer implementation explicitly.
- **Explicitly deferred pending owner approval (production-data impact)**: wallet read-split (balance privacy) — schema change across Functions+rules+client; money minor-units migration in Functions.
- **Verification**: `tsc` build of functions; rules reviewed against test matrix (emulator if available).

### Phase 5 — Money type + formatting (client)
- **Objective**: exact monetary representation client-side.
- **Work**: `Money` value (int minor units) in domain entities, mapped at data layer (wire format unchanged); intl formatting everywhere; kill all `toStringAsFixed`/raw interpolation.
- **Verification**: unit tests for Money + updated bloc tests.

### Phase 6 — Responsive/adaptive shell + UI fixes
- **Objective**: real adaptive layout; close §H P1s.
- **Work**: `StatefulShellRoute` + `NavigationBar`/`NavigationRail`; dark-mode contrast; tooltips/semantics/touch-target pass; payment-request loading/error triad; scrollable dialogs; `confirmDismiss`.
- **Verification**: analyze; widget tests for shell + payment-request states.

### Phase 7 — Localization + accessibility completion
- **Objective**: zero hardcoded user-facing strings.
- **Work**: full en ARB extraction (~160 strings incl. failure messages); intl number/date/currency everywhere; a11y labels for all interactive elements.
- **Verification**: grep proves no raw `Text('…')` literals in features; analyze + tests.

### Phase 8 — Pending owner decisions (blocked, not forgotten)
- Backend money minor-units migration (production data).
- Wallet read-split for balance privacy (schema migration).
- Real Firebase project separation (dev vs prod are the **same project** today: `firebase_options_dev.dart:50` == `firebase_options_prod.dart:50`, `.firebaserc` single alias) and iOS flavor wiring (no Podfile/schemes — iOS `--flavor` builds fail).
- App Check implementation (docs currently overclaim it).
- CI/CD (GitHub Actions: analyze + test + rules tests).

### Phase 9 — Testing completion
Per §J priorities: payment-request/contacts/notifications bloc tests, redirect tests, Money tests, functions tests, emulator rules suite.

---

## M. Definition of Done

1. `flutter pub get`, `flutter analyze` (very_good_analysis, zero issues), `flutter test` all pass on the environment's stable toolchain — reproducible from a clean clone with codegen.
2. No client code path can render an authenticated screen while logged out (router-enforced, tested).
3. No debug surface reachable in production builds (flag-gated, tested).
4. All monetary values in client code flow through the `Money` type; zero `toStringAsFixed`/raw-amount display sites.
5. Domain layer imports no `data/` symbol anywhere (grep-verified); dead files from §K.5 deleted.
6. Rules/functions fixes from Phase 4 deployed-ready with `tsc` green; the two production-data migrations are documented decision requests, not silent gaps.
7. Every page implements loading/empty/error; every amount and date is intl-formatted; no hardcoded user-facing strings outside ARB; adaptive navigation works at phone and tablet/desktop widths.
8. Money-mutating flows (transfer create/accept/decline) and the auth gate have passing bloc/repository tests; fraud-constant and currency-assertion have functions tests.
9. Documentation (README, ARCHITECTURE.md, SOURCE_OF_TRUTH.md, docs/*) matches verified code behavior; this plan updated with phase completion status after each phase.

---

## Appendix: Product-scope assessment (MVP)

**Required (present, needs hardening)**: auth ✅, wallet lifecycle ✅ (provision/idempotent), transfers ✅ (backend-authoritative), transactions ✅ (paged, filtered), payment requests ✅, recipients/contacts ✅, notifications ✅, notification preferences ✅, profile + account deletion ✅ (guarded by zero-balance/history checks), reconciliation/audit/event-sourcing ✅ (Functions), fraud/velocity ✅ (needs the §G fixes), themes ✅.

**Recommended (missing)**: transaction detail view; fee concepts; dispute/refund; session/device management; App Check; error monitoring (Sentry-class); CI; dev/prod project separation; iOS parity.

**Optional / Out of scope for MVP**: multi-currency FX, admin console UI, financial reporting exports (BigQuery streaming already exists as the foundation), card issuing, KYC.

*This appendix lists scope, not commitments — items enter the phase plan only when pulled into §L.*
