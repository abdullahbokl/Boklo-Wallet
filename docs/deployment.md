# 🚀 Deployment Guide

This guide details how to deploy the **Boklo Wallet** backend and frontend applications.

---

## ☁️ Backend Deployment

The backend consists of **Cloud Functions**, **Firestore Rules**, **Storage Rules**, and **Eventarc Triggers**.

### Pre-Requisites

1.  **Authorize Firebase CLI**:
    ```bash
    firebase login
    ```
2.  **Verify Project**:
    Ensure `.firebaserc` points to the correct production project ID.
    ```bash
    cat .firebaserc
    ```

### 1. Deploy Cloud Functions

Functions are located in the `functions/` directory.

```bash
# 1. Install dependencies & Build
cd functions
npm install
npm run build

# 2. Deploy only functions
firebase deploy --only functions
```

> **Note:** If you added new environment variables, update them using:
> `firebase functions:config:set some.key="value"`

### 2. Deploy Security Rules

Crucial for enforcing the "Backend Authority" model.

```bash
# Deploy Firestore Rules
firebase deploy --only firestore:rules

# Deploy Storage Rules
firebase deploy --only storage
```

### 3. Deploy Indexes

If you see "Index missing" errors in logs:

```bash
firebase deploy --only firestore:indexes
```

---

## 📱 Frontend Deployment

### Android (Play Store)

1.  **Key Store**: Ensure `upload-keystore.jks` is present in `android/app/`.
2.  **Properties**: Helper file `key.properties` must reference the keystore.
3.  **Build App Bundle**:

    ```bash
    flutter build appbundle --flavor prod -t lib/main_prod.dart
    ```

    _Output:_ `build/app/outputs/bundle/prodRelease/app-prod-release.aab`

4.  **Upload**: Upload `.aab` to Google Play Console.

### iOS (App Store)

1.  **Pod Install**:
    ```bash
    cd ios
    pod install
    cd ..
    ```
2.  **Build Archive**:

    ```bash
    flutter build ipa --flavor prod -t lib/main_prod.dart --export-method=app-store
    ```

    _Output:_ `build/ios/archive/Runner.xcarchive`

3.  **Upload**: Use **Transporter** app or Xcode to upload the `.ipa` / archive.

---

## 🔄 CI/CD Automation

(If Fastlane or GitHub Actions is set up, document it here.)

- _Currently manual deployment is assumed._
