# Production Readiness

## 1. Deployment Strategy

### Strict Deployment Order

In an event-driven system, dependencies matter. We deploy from the "bottom up" of the data flow.

1.  **Firestore Security Rules:** Secure the data first.
    ```bash
    firebase deploy --only firestore:rules
    ```
2.  **Cloud Functions (Backend Logic):** Ensure handlers exist before events are fired.
    ```bash
    firebase deploy --only functions
    ```
3.  **Eventarc Triggers:** Route events to the new functions.
    _(Auto-deployed with functions usually, but conceptual separation is important)_
4.  **Flutter App (Client):** Deploy the UI last, once the backend supports it.

### Versioning

- Use Semantic Versioning for the App (v1.0.0).
- Cloud Functions should theoretically support backward compatibility (n-1 support) to handle older app clients still in the wild.

## 2. Rollback Strategy

### "Backend First" Rollback

If a deployment fails:

1.  **Revert Cloud Functions** to the previous stable git hash.
2.  **Revert Security Rules** if they were tightened too much.
3.  **App Rollback:** On stores, this is slow. Use Feature Flags (Remote Config) to disable broken new features immediately without waiting for a store review.

**Data Integrity Rule:** Never rollback the _Ledger_. If bad data was written, write a **compensating transaction** (a counter-entry) to fix the balance. Nuke-and-pave is not an option in FinTech.

## 3. IAM & Security

### Service Accounts

- **App:** Runs as an authenticated user (limited scope).
- **Functions:** Runs as `App Engine Default Service Account` (or custom SA). Has `Firestore Admin` and `Eventarc Receiver` roles.
- **CI/CD:** Use a dedicated Service Account with minimal permissions for headers/deployment.

### API Keys

- Restricted by Bundle ID (iOS) and SHA-1 (Android) in Google Cloud Console.
- Never commit unrestricted API keys.

## 4. Observability

### Logs

- **Structured Logging:** Use JSON logs in Cloud Functions for queryability.
- **Correlation IDs:** Pass a `transactionId` through the entire chain (App -> Firestore -> Function -> Logs) to trace requests.

### Monitoring

- **Crashlytics:** For Flutter app crashes.
- **Cloud Monitoring:** Set alerts for:
  - Function execution errors > 1%.
  - High latency on `onTransactionCreated`.
  - Eventarc delivery failures.

## 5. Emulator vs. Production

### The Golden Rule

**"It works on my machine" is not enough.**

- **Emulator:** Used for logic verification and rapid iteration.
- **Physical Device Dev:** MUST use real Firebase Auth (due to SafetyNet/Play Integrity) but can point to Firestore Emulator.
- **Staging:** A separate Firebase project mirroring prod.
- **Production:** The live environment.

### Toggle Logic

The app detects the environment at runtime:

```dart
if (kDebugMode) {
  // Use Emulators
} else {
  // Use Real Services
}
```

_Note: We add a strictly visible "Video Game Mode" banner or indicator when running on emulators to prevent accidental usage in prod._
