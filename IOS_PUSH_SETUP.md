# iOS Push Notification Setup Guide

Notification setup for iOS requires manual steps in the Apple Developer Portal and Xcode. It cannot be fully automated.

## 1. Apple Developer Portal

1.  **Log in** to your Apple Developer Account.
2.  Go to **Certificates, Identifiers & Profiles**.
3.  **Authentication Key (Recommended)**:
    - Select **Keys** from the side menu.
    - Click the **(+)** button to create a new key.
    - Name it (e.g., `Boklo Wallet Push Key`).
    - Check **Apple Push Notifications service (APNs)**.
    - Click **Continue** -> **Register**.
    - **Download** the `.p8` file. **Store this safely**; it can only be downloaded once.
    - Note the **Key ID** and your **Team ID**.

## 2. Firebase Console

1.  Open your **Boklo Wallet** project in Firebase Console.
2.  Go to **Project Settings** -> **Cloud Messaging**.
3.  Scroll to **Apple app configuration**.
4.  Upload the **APNs Authentication Key** (.p8) you just downloaded.
5.  Enter the **Key ID** and **Team ID**.

## 3. Xcode Configuration

1.  Open `ios/Runner.xcworkspace` in Xcode.
2.  Select the **Runner** project in the navigator.
3.  Select the **Runner** target.
4.  Go to the **Signing & Capabilities** tab.
5.  **Capability: Push Notifications**:
    - Click **+ Capability**.
    - Search for and add **Push Notifications**.
6.  **Capability: Background Modes**:
    - Click **+ Capability**.
    - Search for user **Background Modes**.
    - Check **Remote notifications**.
    - _(Note: This is already enabled in `Info.plist`, but verifying in Xcode is good practice)_.

## 4. Verification

1.  Build and run the app on a **Physical iOS Device** (Push notifications do NOT work on the Simulator).
2.  Follow the steps in `NOTIFICATION_VERIFICATION.md`.
