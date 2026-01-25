import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import {
  TransferEventType,
  TransactionCreatedEvent,
  TransactionCompletedEvent,
  TransactionFailedEvent,
} from "./domain/events/transfer_events";

// Helper to create event objects
const createEventPayload = (
  transferId: string,
  data: any
) => ({
  transactionId: transferId,
  senderWalletId: data.fromWalletId,
  receiverWalletId: data.toWalletId,
  amount: data.amount,
  currency: data.currency,
});

export const onTransferCreated = onDocumentCreated("transfers/{transferId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    return;
  }

  const transferId = event.params.transferId;
  const transferData = snapshot.data();
  const currentStatus = transferData.status;

  // Idempotency: Only process if status is 'pending'
  if (currentStatus !== "pending") {
    logger.info("Transfer execution skipped", {
      event: "TRANSFER_EXECUTION",
      status: "SKIPPED",
      transactionId: transferId,
      reason: `Status is ${currentStatus}`
    });
    return;
  }

  logger.info("Transfer execution started", {
    event: "TRANSFER_EXECUTION",
    status: "STARTED",
    transactionId: transferId
  });

  const startTime = Date.now();

  const db = admin.firestore();

  // EMIT: transaction.created
  // We use a deterministic ID to prevent duplicate events on retries
  const createdEventId = `${transferId}_created`;
  const createdEvent: TransactionCreatedEvent = {
    eventId: createdEventId,
    eventType: TransferEventType.CREATED,
    occurredAt: new Date().toISOString(),
    ...createEventPayload(transferId, transferData),
  };

  // We write this separately (not in the transaction below) because it signifies
  // the *attempt* was recognized. worst case if function fails before transaction,
  // we have a created event but no completion.
  try {
    await db.collection("events").doc(createdEventId).create(createdEvent);
  } catch (e: any) {
    // If it already exists, that's fine (idempotency).
    if (e.code !== 6 /* ALREADY_EXISTS */) {
      logger.error("Failed to emit created event", {
        event: "EVENT_EMISSION",
        status: "FAILED",
        transactionId: transferId,
        error: e.message
      });
    }
  }

  const fromWalletId = transferData.fromWalletId;
  const toWalletId = transferData.toWalletId;
  const amount = transferData.amount;

  // Validation: Initial Checks
  if (fromWalletId === toWalletId) {
    await updateAsFailed(db, transferId, "Sender and receiver cannot be the same", transferData);
    return;
  }

  try {
    await db.runTransaction(async (t) => {
      const transferRef = db.collection("transfers").doc(transferId);
      const fromWalletRef = db.collection("wallets").doc(fromWalletId);
      const toWalletRef = db.collection("wallets").doc(toWalletId);

      // Transactional Idempotency Check
      // We re-read the transfer doc INSIDE the transaction to ensure no concurrent
      // execution has changed the status since our initial check.
      const freshTransferDoc = await t.get(transferRef);
      if (freshTransferDoc.data()?.status !== "pending") {
        throw new Error("Transfer already processed (concurrent)");
      }

      const fromWalletDoc = await t.get(fromWalletRef);
      const toWalletDoc = await t.get(toWalletRef);

      if (!fromWalletDoc.exists || !toWalletDoc.exists) {
        throw new Error("One or both wallets do not exist");
      }

      const fromBalance = fromWalletDoc.data()?.balance || 0;
      if (fromBalance < amount) {
        throw new Error("Insufficient balance");
      }

      // 1. Deduct from Sender
      t.update(fromWalletRef, {
        balance: FieldValue.increment(-amount),
      });

      // 2. Credit to Receiver
      t.update(toWalletRef, {
        balance: FieldValue.increment(amount),
      });

      // 3. Create Transaction Records (Subcollection)
      const timestamp = FieldValue.serverTimestamp();
      const fromTransactionRef = fromWalletRef.collection("transactions").doc();
      const toTransactionRef = toWalletRef.collection("transactions").doc();

      t.set(fromTransactionRef, {
        id: fromTransactionRef.id,
        transferId: transferId,
        amount: amount,
        type: "debit",
        counterpartyId: toWalletId,
        timestamp: timestamp,
        status: "completed",
        description: `Transfer to ${toWalletDoc.data()?.alias || toWalletId}`,
      });

      t.set(toTransactionRef, {
        id: toTransactionRef.id,
        transferId: transferId,
        amount: amount,
        type: "credit",
        counterpartyId: fromWalletId,
        timestamp: timestamp,
        status: "completed",
        description: `Transfer from ${fromWalletDoc.data()?.alias || fromWalletId}`,
      });

      // 4. Update Transfer Status
      t.update(transferRef, {
        status: "completed",
        completedAt: timestamp,
      });

      // 5. EMIT: transaction.completed
      const completedEvent: TransactionCompletedEvent = {
        eventId: `${transferId}_completed`,
        eventType: TransferEventType.COMPLETED,
        occurredAt: new Date().toISOString(),
        ...createEventPayload(transferId, transferData),
      };
      const eventRef = db.collection("events").doc(completedEvent.eventId);
      t.set(eventRef, completedEvent);
    });

      logger.info("Transfer execution completed", {
        event: "TRANSFER_EXECUTION",
        status: "COMPLETED",
        transactionId: transferId,
        durationMs: Date.now() - startTime
      });
  } catch (error: any) {
    logger.error("Transfer execution failed", {
        event: "TRANSFER_EXECUTION",
        status: "FAILED",
        transactionId: transferId,
        error: error.message,
        durationMs: Date.now() - startTime
    });
    // Determine if we should mark as failed or just log (e.g. concurrent error vs logic error)
    // For "Transfer already processed", we exit gracefully.
    if (error.message === "Transfer already processed (concurrent)") {
      return;
    }

    // For logic errors (balance, existing wallets), we update status to FAILED.
    await updateAsFailed(db, transferId, error.message, transferData);
  }
});

async function updateAsFailed(
  db: admin.firestore.Firestore,
  transferId: string,
  reason: string,
  transferData: any
) {
  // We use a transaction here too to ensure we emit the event atomically with the failure update
  // effectively closing the loop.
  try {
    await db.runTransaction(async (t) => {
        const transferRef = db.collection("transfers").doc(transferId);
        t.update(transferRef, {
            status: "failed",
            failureReason: reason,
        });

        // EMIT: transaction.failed
        const failedEvent: TransactionFailedEvent = {
            eventId: `${transferId}_failed`,
            eventType: TransferEventType.FAILED,
            occurredAt: new Date().toISOString(),
            ...createEventPayload(transferId, transferData),
            failureReason: reason,
        };
        const eventRef = db.collection("events").doc(failedEvent.eventId);
        t.set(eventRef, failedEvent);
    });
  } catch (e) {
      logger.error("Failed to mark transfer as failed", {
        event: "TRANSFER_STATUS_UPDATE",
        status: "FAILED",
        transactionId: transferId,
        error: e instanceof Error ? e.message : 'Unknown error'
      });
  }
}
