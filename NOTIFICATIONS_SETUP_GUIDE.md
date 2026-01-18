# 🔔 Notifications Setup Guide

This guide ensures Firebase Cloud Messaging (FCM) works on both Android and iOS.

---

## 🤖 Android Setup (Code Updated)

**Status:** ✅ Code configured.

The following changes have been made automatically:

1.  **Permission**: `POST_NOTIFICATIONS` is added to `AndroidManifest.xml`.
2.  **SDK**: `compileSdk` and `targetSdk` set to `36`.
3.  **Foreground**: App logic now manually shows notifications when the app is open.

**Action Required:**

- None. Just build and run.

---

## 🍎 iOS Setup (Manual Action Required)

**Status:** ❌ **BLOCKER** - Requires Apple Developer Account Access.

You **MUST** perform these steps to enable notifications on iOS.

### 1️⃣ Add Capabilities in Xcode

1.  Open `ios/Runner.xcworkspace` in Xcode.
2.  Select **Runner** (Project) > **Signing & Capabilities**.
3.  Click **+ Capability** and add:
    - **Push Notifications**
    - **Background Modes** (Check: _Remote notifications_)

### 2️⃣ Generate APNs Authentication Key (.p8)

1.  Log in to [Apple Developer Console](https://developer.apple.com/account).
2.  Go to **Certificates, Identifiers & Profiles** > **Keys**.
3.  Click **(+)** to create a new key.
4.  Name it "Firebase Push" and check **Apple Push Notifications service (APNs)**.
5.  **Download** the `.p8` file (Keep it safe!).
6.  Note the **Key ID** and your **Team ID** (top right of page).

### 3️⃣ Configure Firebase Console

1.  Go to [Firebase Console](https://console.firebase.google.com/).
2.  Select your project > **Project Settings** (gear icon) > **Cloud Messaging**.
3.  Scroll to **Apple app configuration**.
4.  Under **APNs Authentication Key**, click **Upload**.
5.  Upload the `.p8` file and enter your **Key ID** and **Team ID**.

---

## 🧪 Verification Plan

### Test Android

1.  Install app on device/emulator (API 33+).
2.  Allow Notification Permission when prompted.
3.  **Foreground**: App open -> Trigger notification -> Banner appears ✅.
4.  **Background**: Minimize app -> Trigger notification -> Banner appears ✅.
5.  **Terminated**: Kill app -> Trigger notification -> Banner appears ✅.

### Test iOS

1.  **Prerequisite**: Steps above MUST be completed.
2.  Run on **Physical Device** (Simulators often fail with remote push).
3.  Allow Permission.
4.  Repeat Foreground/Background/Terminated tests.

---

## ❓ Troubleshooting

- **No Notification in Foreground?**
  - Check Logs: `Message also contained a notification...` means the app received it.
  - If banner missing: Check `flutter_local_notifications` channel setup (Auto-handled in code).

- **iOS: "Error: Missing APNs Key"**
  - Verify Step 3 in iOS Setup.
