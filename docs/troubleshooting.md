# 🛠 Troubleshooting Guide

Common issues encountered when developing the **Boklo Wallet** application.

---

## 🔔 Notifications Not Working

### Symptom

Transfer completed on backend, but no notification appears on the device.

### Checklist

1.  **Check Backend Function**:
    - Find the `onTransactionCompleted` Cloud Function logs.
    - Look for "Sending Notification..." or "Error sending notification".
2.  **Verify Device Token**:
    - Open Firestore: `users/{uid}/tokens/{fcmToken}`.
    - Ensure a document exists for the target user.
3.  **Android Channel Issues**:
    - Check `AndroidManifest.xml` for `<meta-data android:name="com.google.firebase.messaging.default_notification_channel_id" ... />`.
    - Ensure it points to `high_importance_channel` created in `LocalNotificationService.dart`.
4.  **Google Play Services Error**:
    - Logs show `API: Phenotype.API is not available`.
    - **Fix**: This usually happens on emulators without Google Play or if `applicationId` mismatches `google-services.json`. Ensure `debug.keystore` SHA-1 is added to the Firebase Console.

---

## 🌐 Emulator Connection Refused

### Symptom

App shows network errors or timeouts when connecting to `10.0.2.2:xxxx`.

### Checklist

1.  **Is Emulator Running?**:
    - Run `./scripts/start_emulators.sh`.
    - Wait for "All emulators ready".
2.  **Physical Device?**:
    - Physical Android devices cannot reach `10.0.2.2`.
    - **Fix**: Run with your machine's local IP:
      ```bash
      flutter run --debug --flavor dev --dart-define=EMULATOR_HOST=192.168.1.X
      ```
3.  **Correct Ports?**:
    - Check `emulator_config.dart`.
    - Defaults: Auth(9098), Firestore(8086), Functions(5001), Storage(9200).
    - Ensure `firebase.json` matches these ports.
    - If you changed ports in `firebase.json`, pass matching app values with `--dart-define`.

4.  **Firestore Port Already Taken?**:
    - `./scripts/start_emulators.sh` automatically clears stale Firebase emulator Java processes using configured emulator ports.
    - If the port is owned by a non-Firebase process, the script fails with the owning PID/command so you can resolve it once.

---

## 🔐 App Check / Authentication Failures

### Symptom

"403 Forbidden" or "Invalid App Check Token" in logs.

### Checklist

1.  **Debug Token**:
    - When checking logs, find the line: "Enter this debug secret into the allow list...".
    - Copy the UUID and add it to **Firebase Console -> App Check -> Apps -> Manage debug tokens**.
2.  **SHA-1 Fingerprint**:
    - For Google Sign-In and Phone Auth on Android, the signing key SHA-1 must be added to Firebase Console -> Project Settings.
    - This is required even for Debug builds if you are using a real backend (Prod mode).

---

## 📦 Build Failures

### Symptom

`Execution failed for task ':app:processDebugGoogleServices'.`

### Fix

- Ensure `google-services.json` is present in `android/app/`.
- If using flavors, you might need specific `src/dev/google-services.json` and `src/prod/google-services.json`.
- Check if `applicationId` in `build.gradle` matches the package name in `google-services.json`.
