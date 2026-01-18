# Notification End-to-End Verification Checklist

Use this checklist to verify the correct implementation of Firebase Cloud Messaging (FCM) notifications for Boklo Wallet.

## 1. Prerequisites

- [ ] **Physical Device** or **Emulator with Google Play Services** is used.
- [ ] App is installed and **Logged In**.
- [ ] Notification permissions are **Granted**.

## 2. Setup Verification

- [ ] **Check Logs**: Filter logs for `FCM Token`. Expect: `FCM Token: <token_string>`
- [ ] **Check Firestore**: Go to `users/{userId}/tokens`. Expect document ID matching the token.

## 3. Test Scenarios

### A. Foreground Notification

_App is open and visible._

1. **Trigger**: Perform a transfer.
2. **Observation**:
   - [ ] No system notification (standard behavior).
   - [ ] Log: `Got a message whilst in the foreground!`.
   - [ ] Firestore: `notifications` doc has `status: 'SENT'`.

### B. Background Notification

_App is minimized._

1. **Trigger**: Perform a transfer (use another device/simulator).
2. **Observation**:
   - [ ] **System Notification** appears.
   - [ ] Title: "Transfer Sent" / "Money Received".
   - [ ] Tap notification -> App opens (resumes).
   - [ ] Log: `Message data: ...`.

### C. Terminated Notification

_App is closed._

1. **Trigger**: Perform a transfer.
2. **Observation**:
   - [ ] **System Notification** appears.
   - [ ] Tap notification -> App launches.
   - [ ] Log: `App opened from terminated state...`.

## 4. Integrity Checks

- [ ] **No Duplicates**: One notification per event.
- [ ] **Cleanup**: Uninstall app (invalidates token), trigger notification. Check logs for `Cleaning up... invalid tokens`.
