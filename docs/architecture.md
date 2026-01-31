# Boklo Wallet Architecture

## 1. System Overview

Boklo Wallet is a Flutter-based FinTech application built on a **backend-authoritative, event-driven** architecture using Firebase. The system prioritizes financial correctness, security, and idempotency over client-side convenience.

### Core Philosophy

- **Client as Observer:** The Flutter app is a "dumb" terminal that observes state. It never mutates financial data directly.
- **Backend as Authority:** Cloud Functions and Firestore are the single source of truth for all balances and transactions.
- **Event-Driven:** Business logic is decoupled and triggered by asynchronous events, ensuring scalability and traceability.

## 2. Backend-Authoritative Flow

Unlike traditional CRUD apps where the client might optimistically update a balance, Boklo Wallet strictly forbids this.

### The Transfer Lifecycle

1.  **Intent (Flutter):** User initiates a transfer. App writes a `Transaction` document to Firestore with status `PENDING`.
2.  **Routing (Eventarc):** Firestore write triggers an Eventarc event (`google.cloud.firestore.document.v1.created`).
3.  **Execution (Cloud Functions):**
    - Function receives the event.
    - Validates business rules (balance check, user existence).
    - Performs atomic ledger entries.
    - Updates `Transaction` status to `COMPLETED` or `FAILED`.
4.  **Reaction (Flutter):**
    - UI listens to the `Transaction` document stream.
    - Updates UI automatically when status changes.
    - **Note:** The app _never_ simply "sets" the balance. It waits for the backend to update the Wallet document.

## 3. Event-Driven Pipeline

The architecture relies on a strict pipeline to decouple services:

`Firestore (Data) -> Eventarc (Router) -> Cloud Functions (Logic) -> Ledger/Notification (Action)`

- **Firestore:** Stores state (Wallets, Transactions).
- **Eventarc:** Routes state changes to consumers without knowing what the consumers do.
- **Cloud Functions:**
  - `onTransactionCreated`: Validates and executes transfers.
  - `onTransactionCompleted`: Sends notifications, updates analytics.
- **Ledger:** An append-only collection that records every financial movement.
- **Notifications:** Decoupled from the transaction logic. A separate function listens for `completed` events to send push notifications.

## 4. Ledger Truth & Derived Balances

### The Ledger

The `Ledger` collection is the financial backbone.

- **Append-Only:** Records cannot be modified, only added.
- **Source of Truth:** If the Wallet balance disagrees with the sum of Ledger entries, the Ledger is right (and a reconciliation job fixes the Wallet).

### Derived Balances

- The `Wallet` document contains a `balance` field.
- This field is a **read optimization** (materialized view) for the UI.
- It is updated atomically alongside the Ledger entry by the backend.

## 5. Security & Idempotency

### Idempotency

- Every transfer must be idempotent.
- If a Cloud Function retries (due to timeout or error), it must distinctively identify that the transaction was already processed (via `transactionId`) and not deduct money twice.

### Firestore Rules

- **No Writes to Balance:** Security rules explicitly deny any write operation to `wallet.balance` from the client SDK.
- **Ownership:** Users can only read/write their own transaction intents.

### Role-Based Access

- Backend functions run with privileged service accounts.
- Client runs with restricted identified user credentials.
