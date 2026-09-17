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
  - Creates transactions with `PENDING` status only
  - Observes results (`COMPLETED` / `FAILED`)
  - **Never mutates balances**

### High-Level Flow

```

Flutter (Intent)
↓
Firestore (Transfer Request)
↓
Eventarc (Routing only)
↓
Cloud Functions (Authoritative execution)
↓
Ledger append + Wallet balance update
↓
Domain events
↓
Reactive UI + Notifications

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
  - Analytics (Day-2)

### Core Events

- `transaction.created`
- `transaction.completed`
- `transaction.failed`

### Event Rules

- No business logic in Eventarc
- Eventarc = **router only**
- Event consumers must be:
  - Stateless
  - Independent
  - Idempotent

---

## 3️⃣ Ledger Rules (Financial Truth)

- Ledger is **append-only**
- One ledger entry per wallet per **completed** transaction
- Ledger **never updates balances**
- Balances are **derived views**
- Ledger is the **single financial source of truth**

---

## 4️⃣ Wallet Resolution (Unified Logic)

- All wallet lookups go through a **single resolver**
- Supported identifiers:
  - Wallet ID
  - User ID
  - Email
- Resolution pipeline:

```

Input → WalletResolver → Wallet Document

```

- No duplicated wallet lookup logic across features

---

## 5️⃣ Security Rules (Strict)

### Client (Flutter)

- Can:
  - Create transactions (`PENDING`)
  - Read wallets, ledger, transactions
- Cannot:
  - Update balances
  - Update transaction status
  - Trigger notifications

### Backend

- Can:
  - Validate transfers
  - Update balances
  - Finalize transactions
- Uses **service accounts only**
- All transfers must be **idempotent**

---

## 6️⃣ State Management (Flutter)

- Cubit / Bloc only
- No direct Firebase calls in UI
- UI reacts to state changes only
- No polling
- No manual refresh
- All lists (transactions, wallets) must be **reactive**

---

## 7️⃣ Reusability Rules (Mandatory)

- No direct usage of:
  - `Navigator`
  - `ScaffoldMessenger`
- Use:
  - `NavigationService`
  - `SnackbarService`
- Enforce:
  - DRY
  - SOC
- Widgets must be:
  - Small
  - Reusable
  - ≤ 120 lines per file

---

## 8️⃣ Firebase Emulators — Dev Rules (Critical)

### General

- Emulator setup is **DEV-only**
- Must run:
  - After `Firebase.initializeApp()`
  - Before any Firebase usage

### Emulator Host Rules

| Platform         | Firebase Auth | Firestore / Functions / Storage |
| ---------------- | ------------- | ------------------------------- |
| Android Emulator | Emulator      | Emulator                        |
| Physical Android | ❌ Real Auth  | Emulator                        |
| Web / Desktop    | Emulator      | Emulator                        |
| Production       | Real          | Real                            |

> Firebase Auth Emulator is **not reliably supported** on physical Android devices.

### Physical Device Networking

- Emulator host must be passed via:

```

--dart-define=EMULATOR_HOST=<LOCAL_MACHINE_IP>

```

- `localhost` **does NOT work**
- `network_security_config.xml` is mandatory
- Hot restart is **not sufficient** after network changes

---

## 9️⃣ Firebase Auth (Source of Truth)

- Auth Emulator:
  - Works reliably **only on Android Emulator**
- Physical Android:
  - Must use **real Firebase Auth**
- reCAPTCHA errors are **Firebase limitations**
- Do **not** force Auth Emulator on physical devices

---

## 🔟 App Check Rules

> Status: Active in-app (Play Integrity / App Attest; debug provider in dev).
> Console-side enforcement per product is an operations decision.

- Disabled or Debug Provider in DEV
- Must not block emulator traffic
- Enabled only in production

---

## 1️⃣1️⃣ Notifications Rules

- Notifications are **backend-only**
- Triggered strictly by **domain events**
- Firebase Cloud Messaging (HTTP v1)
- Requirements:
  - Idempotent
  - Non-blocking
  - Side-effect free
- Emulator:
  - No delivery (expected)
  - Logic verified via logs
- Real devices:
  - Fully functional

---

## 1️⃣2️⃣ Testing Rules

### Automated

- Transfer validation tests
- Wallet Cubit tests
- Repository tests
- Emulator smoke tests
- Notification verification scripts

### Manual

- Login persistence
- Wallet auto-load
- Transfer success/failure
- Balance update after backend event
- Live transaction history
- Push notification delivery

---

## 1️⃣3️⃣ Deployment Rules

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

## 1️⃣4️⃣ Commit Message Convention

- Commits must describe:
  - **What** changed
  - **Why** it changed
- Never describe implementation details

Examples:

- `feat(backend): backend-authoritative transfers`
- `fix(dev): physical android auth stability`

---

## 1️⃣5️⃣ What Must NEVER Be Done

❌ Client-side balance mutation  
❌ Forcing Auth Emulator on physical Android  
❌ Business logic in Eventarc  
❌ Polling or manual refresh  
❌ Bypassing Cubit / Bloc  
❌ Modifying production behavior for dev fixes

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

Any deviation requires **explicit architectural approval**.
