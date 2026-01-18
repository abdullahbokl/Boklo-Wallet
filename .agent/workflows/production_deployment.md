
## 📁 `.agent/workflows/production_deployment.md`

```md
---
description: Production Deployment Workflow for Backend-Authoritative, Event-Driven Transfers
---

# 🚀 Production Deployment Workflow — Boklo Wallet

This workflow defines the **ONLY approved production deployment process**
for Boklo Wallet.

⚠️ This workflow is **procedural, not generative**.
The agent must NOT implement new features while executing it.

---

## 🎯 Scope

This deployment covers:

- Backend-authoritative transfer execution
- Event-driven transaction lifecycle (Eventarc)
- Ledger-based balance consistency
- Reactive transaction history in Flutter
- Strict security rules (client is read-only for balances)

---

## 🧠 Architectural Preconditions (HARD BLOCKERS)

Deployment MUST NOT proceed unless all are true:

- Flutter does **NOT** mutate balances
- Backend is the **single authority** for:
  - Balance updates
  - Transaction finalization
- Eventarc is used as **orchestrator only**
- Ledger is append-only and immutable

If any condition is violated → **STOP DEPLOYMENT**

---

## ⚠️ Pre-Deployment Checklist (MANDATORY)

Before starting, ensure:

- [ ] Working directory is clean
- [ ] Correct release branch is checked out
- [ ] Firebase CLI authenticated with **production project**
- [ ] Emulator configuration is **disabled** in prod builds
- [ ] Feature flag  
  `backendAuthoritativeTransfers = true`
  is enabled in:
```

lib/core/di/app\_module.dart

```
- [ ] Production build uses:
```

lib/main\_prod.dart\
\--flavor prod

````

---

## 🟩 STEP 1 — Lock the Data Layer (FIRST, ALWAYS)

### 1.1 Deploy Firestore Security Rules

This prevents any client-side balance mutation.

```bash
firebase deploy --only firestore:rules
````

✅ Verify:

* Wallet balances are writable **only** by backend service account

* Transfer documents are immutable after creation

***

## 🟩 STEP 2 — Deploy Backend Execution Layer

### 2.1 Deploy Cloud Functions

Deploy backend authority + event publishers.

```bash
firebase deploy --only functions:transfers-onTransferCreated,events_publisher-onEventCreated,smoke_test-onTransactionCompletedLog
```

✅ Verify in logs:

* Transfer validation

* Idempotent execution

* Balance updates

* Event emission

***

### 2.2 Verify Eventarc Routing

Ensure events are correctly routed.

```bash
gcloud eventarc triggers list --location=us-central1
```

✅ Expected:

* Trigger for transaction creation

* Trigger for transaction completion

Eventarc must:

* Route events only

* Contain NO business logic

***

## 🟩 STEP 3 — Data Consistency Validation

### 3.1 Smoke Test (Backend)

* Create a transfer using a test account

* Observe logs:

Expected sequence:

1. `transaction.created`

2. Backend validation

3. Ledger entry creation

4. Balance update

5. `transaction.completed`

***

### 3.2 Idempotency Verification

* Re-emit same event / retry function

* Ensure:

  * No duplicate ledger entries

  * No double balance mutation

***

## 🟩 STEP 4 — Deploy Flutter App (LAST)

### 4.1 Build Production App

```bash
flutter build appbundle --release --flavor prod -t lib/main_prod.dart
# OR
flutter build ipa --release --flavor prod -t lib/main_prod.dart
```

⚠️ MUST be built with:

* `backendAuthoritativeTransfers = true`

* No emulator flags

* Real Firebase Auth

***

### 4.2 Publish

* Upload to Play Store / App Store

* Release gradually (recommended)

***

## 🟩 STEP 5 — Post-Deployment Monitoring (24h)

Monitor:

### Backend

* Firebase Console → Functions

* Cloud Logging:

  ```
  severity=ERROR
  ```

### Events

* Eventarc delivery success

* No dropped or duplicated events

### Data

* Ledger entries match balances

* No orphaned transactions

***

## 🔄 Rollback Strategy (SAFE ORDER)

If a critical issue occurs:

### Option 1 — Fast UI Rollback

* Disable feature flag:

  ```
  backendAuthoritativeTransfers = false
  ```

* Release hotfix Flutter build

⚠️ Backend rules may still block unsafe writes

***

### Option 2 — Backend Rollback (Dangerous, Last Resort)

1. Disable Eventarc triggers

2. Roll back Cloud Functions

3. Restore previous Firestore rules **ONLY if required**

```bash
git checkout <previous_commit> -- firestore.rules
firebase deploy --only firestore:rules
```

***

## ✅ Success Criteria

Deployment is considered successful only if:

* Transfers execute correctly

* Balances change **only via backend**

* Transaction history updates reactively (no refresh)

* Notifications sent exactly once

* No regression in wallet or auth flows

***

## 🏁 Final Rule

This workflow must NEVER:

* Introduce client-side balance mutation

* Bypass backend validation

* Add logic to Eventarc

* Modify production behavior implicitly

If uncertainty exists:\
→ **STOP**\
→ Request architectural approval

