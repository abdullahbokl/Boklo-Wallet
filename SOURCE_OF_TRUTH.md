# 🧠 Boklo Wallet — Source of Truth (Architecture & Dev Rules)

> This document defines the **non-negotiable rules** for development,
> architecture, and environment setup in **Boklo Wallet**.
> Any contributor or AI assistant **MUST follow these rules**.

---

## 1️⃣ System Architecture (Non-Negotiable)

### Authority Model

- Flutter is a **client-only observer**
- Backend is the **single authority** for:
  - Balance updates
  - Transfer execution
- Flutter:
  - Creates transactions with `PENDING` status
  - Observes results (`COMPLETED` / `FAILED`)
  - **Never mutates balances**

### Transaction Lifecycle

```

Flutter → create transaction (PENDING)
Backend → validate + execute
Backend → update balances
Backend → emit domain events
Flutter → react to final state

```

---

## 2️⃣ Event-Driven Core (Source of Truth)

### Domain Events

- Events are **immutable**
- Events are emitted by **backend only**
- Events drive:
  - Ledger
  - Notifications
  - Fraud Detection
  - Audit / Compliance

### Core Events

- `transaction.created`
- `transaction.completed`
- `transaction.failed`

### Event Rules

- No business logic in Eventarc
- Eventarc = routing only
- Consumers must be:
  - Independent
  - Idempotent

---

## 3️⃣ Ledger Rules (Financial Truth)

- Ledger is **append-only**
- One ledger entry per wallet per completed transaction
- Ledger **never updates balances**
- Balance = derived view
- Ledger = **source of financial truth**

---

## 4️⃣ Security Rules (Strict)

### Client (Flutter)

- Can create transactions
- Can read wallets and transactions
- **Cannot**:
  - Update balances
  - Update transaction status

### Backend

- Can update balances
- Can update transaction status
- Uses service account only

---

## 5️⃣ State Management (Flutter)

- Cubit / Bloc only
- No direct Firebase calls in UI
- UI reacts to state changes only
- No polling
- No manual refresh
- All lists (transactions) must be reactive

---

## 6️⃣ Reusability Rules (Mandatory)

- No direct usage of:
  - `ScaffoldMessenger`
  - `Navigator`
- Use:
  - `SnackbarService`
  - `NavigationService`
- DRY + SOC enforced
- Widgets must be:
  - Small
  - Reusable
  - ≤ 120 lines per file

---

## 7️⃣ Firebase Emulators — Dev Rules (Critical)

### General

- Emulator config runs **only in dev**
- Must run immediately after `Firebase.initializeApp()`
- Must run **before any Firebase usage**

---

### Emulator Host Rules

| Platform         | Firebase Auth | Firestore / Functions / Storage |
| ---------------- | ------------- | ------------------------------- |
| Android Emulator | Emulator      | Emulator                        |
| Physical Android | ❌ Real Auth  | Emulator                        |
| Web / Desktop    | Emulator      | Emulator                        |
| Production       | Real          | Real                            |

> Firebase Auth Emulator is **not reliably supported** on Android physical devices.

---

### Android Networking Rules

- Physical Android devices:
  - Must allow cleartext HTTP traffic
- `network_security_config.xml` is mandatory
- Hot restart is **not sufficient** after network changes

---

## 8️⃣ Firebase Auth (Source of Truth)

- Firebase Auth Emulator:
  - Works reliably **only on Android Emulator**
- Physical Android devices:
  - Must use **real Firebase Auth**
- reCAPTCHA errors on physical devices are a **Firebase limitation**
- Do **not** attempt to force Auth Emulator on physical devices

---

## 9️⃣ App Check Rules

- App Check is disabled or uses Debug Provider in dev
- App Check must not block emulator traffic
- App Check is enabled only in production

---

## 🔟 Notifications Rules

- Notifications are **event-driven**
- Flutter never triggers notifications directly
- Notifications must be:
  - Idempotent
  - Non-blocking
  - Side-effect free
- Android supported by default
- iOS requires APNs setup (post-MVP)

---

## 1️⃣1️⃣ Deployment Rules

### Deployment Order

1. Firestore Rules
2. Cloud Functions
3. Eventarc
4. Flutter App

### Rollback

- Backend first
- Flutter second
- Data must never be corrupted

---

## 1️⃣2️⃣ Commit Message Convention

- Commits describe:
  - **What** changed
  - **Why** it changed
- Not how it was implemented

Examples:

- `feat(backend): enforce backend-authoritative transfers`
- `fix(dev): stabilize firebase auth on physical android devices`

---

## 1️⃣3️⃣ What Must NEVER Be Done

❌ Reintroduce client-side balance mutation  
❌ Force Firebase Auth Emulator on physical devices  
❌ Add business logic to Eventarc  
❌ Bypass Cubit / Bloc  
❌ Add polling or manual refresh  
❌ Modify production behavior during dev fixes

---

## 🏁 Final Truth

**Boklo Wallet** is an **event-driven, backend-authoritative FinTech system**.

All decisions prioritize:

- Financial correctness
- Auditability
- Security
- Scalability
- Developer sanity

---

### 🔒 This document is the ultimate Source of Truth.

Any deviation requires explicit architectural approval.
