# ☁️ Cloud Functions & Event Architecture Overview

> **Start Here (New Developers):** This document lists all backend Cloud Functions and their triggers. Boklo Wallet is an **Event-Driven, Backend-Authoritative FinTech System**.
>
> - **Backend Authority:** The functions listed below hold the absolute truth for all financial data.
> - **Event-Driven:** Actions propagate through the system via `Eventarc`. One function does one job, then emits an event for others to react.
> - **Immutability:** The Ledger is append-only. We never update past records, only append new correcting entries.

---

## 💸 Transfers & Ledger (Core Financials)

This is the heart of the banking system. These functions handle money movement, balance updates, and financial integrity.

| Function Name           | Trigger                                          | Description                                                                                                                                                                                                                                                                                                                                                            |
| :---------------------- | :----------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`onTransferCreated`** | `firestore.create` <br> `transfers/{transferId}` | **The Orchestrator.** <br> - Triggered when a client creates a `PENDING` transfer document. <br> - **Duties:** Validates sender balance, performs fraud checks, updates wallet balances (derived state), creates transaction records, and emits `created`, `completed`, or `failed` events. <br> - **Critical:** This is the _only_ place where balance updates occur. |
| **`recordLedgerEntry`** | `eventarc` <br> `transaction.completed`          | **The Source of Truth.** <br> - **Duties:** Listens for completed transactions and appends immutable debit/credit entries to the `ledger` collection. <br> - **Immutable:** Once written, ledger entries are never changed. This history allows us to reconstruct balances at any point in time.                                                                       |
| **`reconcileWallets`**  | `schedule` <br> `every day 00:00`                | **Safety Net.** <br> - **Duties:** A daily cron job that recalculates every wallet's balance from the _entire_ ledger history and compares it to the current `wallet.balance`. <br> - **Alerts:** Logs discrepancies for manual review. Does _not_ auto-fix to prevent cascading errors.                                                                               |

---

## 🔔 Event Propagation (The Bridge)

These functions ensure that internal database changes are broadcast to the rest of the system (notifications, analytics, logs).

| Function Name                   | Trigger                                    | Description                                                                                                                                                                                                                                                                   |
| :------------------------------ | :----------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`onEventCreated`**            | `firestore.create` <br> `events/{eventId}` | **The Bridge.** <br> - **Duties:** Listens for new documents in the `events` collection and publishes them to **Eventarc** (Google Cloud's event bus). <br> - **Why?** This decouples Firestore writes from event consumers. A tailored solution for reliable event sourcing. |
| **`onTransactionCompletedLog`** | `eventarc` <br> `transaction.completed`    | **Smoke Test.** <br> - **Duties:** A simple listener that logs completed transactions. <br> - **Use Case:** Verify the Eventarc pipeline is healthy and events are flowing correctly.                                                                                         |

---

## 📲 Notifications

Feedback loops for users. These functions ensure users know what's happening without blocking the core financial transaction.

| Function Name                  | Trigger                                      | Description                                                                                                                                                                                                                                   |
| :----------------------------- | :------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`notifyOnTransferComplete`** | `eventarc` <br> `transaction.completed`      | **Success Notifier.** <br> - Enqueues notification intents for the **Sender** ("Transfer Sent") and **Receiver** ("Money Received").                                                                                                          |
| **`notifyOnTransferFailed`**   | `eventarc` <br> `transaction.failed`         | **Failure Notifier.** <br> - Enqueues a failure notification for the **Sender** explaining why the transfer failed (e.g., Insufficient Funds).                                                                                                |
| **`notifyOnPaymentRequest`**   | `eventarc` <br> `PAYMENT_REQUEST_CREATED`    | **Request Notifier.** <br> - Enqueues a notification for the **Payer** when someone requests money from them.                                                                                                                                 |
| **`onNotificationQueued`**     | `firestore.create` <br> `notifications/{id}` | **Delivery Worker.** <br> - **Duties:** Picks up queued notification intents, fetches the user's FCM tokens, and sends the actual push notification. <br> - **Smart:** Handles token cleanup (removes invalid tokens) and retries on failure. |

---

## 🧾 Payment Requests (P2P)

Logic for users requesting money from each other.

| Function Name                 | Trigger                                         | Description                                                                                                                                                     |
| :---------------------------- | :---------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`onPaymentRequestCreated`** | `firestore.create` <br> `payment_requests/{id}` | - Validates new payment requests (e.g., checks for self-requests or invalid amounts) and emits the creation event.                                              |
| **`acceptPaymentRequest`**    | `https.onCall`                                  | **Callable (Client Triggered).** <br> - Allows a user to accept a request. <br> - **Action:** Verifies balance and creates a `transfer` to fulfill the request. |
| **`declinePaymentRequest`**   | `https.onCall`                                  | **Callable (Client Triggered).** <br> - Allows a user to decline a payment request. Updates status to `DECLINED`.                                               |

---

## 👥 Contacts

User management helpers.

| Function Name    | Trigger        | Description                                                                                                                       |
| :--------------- | :------------- | :-------------------------------------------------------------------------------------------------------------------------------- |
| **`addContact`** | `https.onCall` | **Callable (Client Triggered).** <br> - Looks up a user by email via Firebase Auth and adds them to the requester's contact list. |
