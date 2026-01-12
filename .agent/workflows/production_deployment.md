---
description: Production Deployment Plan for Backend-Authoritative Transfers
---

# Production Deployment Plan: Backend-Authoritative Transfers

This workflow outlines the step-by-step process for deploying the new event-driven, backend-authoritative transfer system to production.

## 🎯 Scope

- Backend-authoritative transfer execution
- Event-driven transaction lifecycle
- Reactive transaction history
- Strict security rules (client read-only balance)

## ⚠️ Pre-Check

Before starting, ensure:

- [ ] Feature flag `backendAuthoritativeTransfers` is enabled (`lib/core/di/app_module.dart`).
- [ ] Working directory is clean and on the correct release branch.
- [ ] You have `firebase-tools` installed and authenticated.

## 🟩 STEP 1: Deploy Backend (Safe Order)

### 1.1 Deploy Firestore Rules

First, lock down the database to prevent client-side balance mutations.

```bash
firebase deploy --only firestore:rules
```

### 1.2 Deploy Cloud Functions

Deploy the new transfer authority and event handling logic.

```bash
firebase deploy --only functions:transfers-onTransferCreated,events_publisher-onEventCreated,smoke_test-onTransactionCompletedLog
```

### 1.3 Configure Eventarc

Ensure triggers are correctly routed.

```bash
# Verify triggers are active
gcloud eventarc triggers list --location=us-central1
```

## 🟩 STEP 2: Data Consistency Validation

1.  **Smoke Test**: Perform a transfer using a test account (if available) or verify via logs.
2.  **Monitor Logs**: Check Cloud Logging for `transfers-onTransferCreated`.
    - Verify `Transaction created` logs.
    - Verify `Balance updated` logs.
    - Verify event emission logs.
3.  **Verify Idempotency**: Ensure no duplicate processing for the same transfer ID.

## 🟩 STEP 3: Deploy Flutter App

Once the backend is stable and verifying rules:

1.  **Build Production Release**:
    ```bash
    flutter build appbundle --release
    # OR
    flutter build ipa --release
    ```
2.  **Verify Feature Flag**: Ensure the build was created with `backendAuthoritativeTransfers = true` (checked in Pre-Check).
3.  **Upload & Release**: Submit to Play Store / App Store.

## 🟩 STEP 4: Post-Deploy Monitoring

Monitor the following dashboards for the first 24 hours:

- **Firebase Console -> Functions**: Check for crash loops or timeout spikes.
- **Google Cloud Logging**: Filter for `severity=ERROR`.
- **Eventarc**: Verify event delivery success rates.

## 🔄 Rollback Plan

If critical issues arise:

1.  **Switch Feature Flag**: Update `remote_config` (if available) or hot-patch `lib/core/di/app_module.dart` to `backendAuthoritativeTransfers: false` and re-deploy the App.
    - _Note: This reverts the UI to optimistic updates, but backend might still reject writes if rules aren't reverted._
2.  **Revert Firestore Rules**:
    - Deploy previous `firestore.rules` that allowed client writes (if absolutely necessary to restore old behavior).
    ```bash
    git checkout <previous-commit-hash> -- firestore.rules
    firebase deploy --only firestore:rules
    ```
3.  **Disable Functions**:
    - Delete or disable the `onTransferCreated` function if it's causing data corruption.

## ✅ Success Criteria

- [ ] Transfers execute successfully.
- [ ] Balances update only via backend.
- [ ] Transaction history updates automatically in the UI without refresh.
- [ ] No regression in other wallet features.
