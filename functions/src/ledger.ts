import { onCustomEventPublished } from "firebase-functions/v2/eventarc";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { TransferEventType, TransactionCompletedEvent } from "./domain/events/transfer_events";
import { LedgerEntry } from "./domain/ledger/ledger_entry";

// Initialize admin if not already done
if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();

export const recordLedgerEntry = onCustomEventPublished(
    {
        eventType: TransferEventType.COMPLETED,
        retry: true, // Enable retry for reliability
    },
    async (event) => {
        logger.info(`Received ${event.type} event: ${event.id}`, { data: event.data });

        // Cast event data to our typed interface
        // Note: Eventarc usually wraps the data. We assume event.data matches the payload.
        const payload = event.data as unknown as TransactionCompletedEvent;

        if (!payload || !payload.transactionId || !payload.amount) {
            logger.error("Invalid event payload", payload);
            return;
        }

        const { transactionId, senderWalletId, receiverWalletId, amount, currency, occurredAt } = payload;

        // ID DETERMINISM:
        // We construct proper Ledger Entry IDs using the TransactionID + Function (DR/CR).
        // This guarantees that for any given TransactionID, we always generate the exact same Ledger IDs.
        // This is CRITICAL for the idempotency check below.
        const debitEntryId = `${transactionId}_DR`;
        const creditEntryId = `${transactionId}_CR`;

        const debitRef = db.collection("ledger").doc(debitEntryId);
        const creditRef = db.collection("ledger").doc(creditEntryId);

        try {
            await db.runTransaction(async (t) => {
                // Idempotency Check: Read both to see if already processed
                const debitDoc = await t.get(debitRef);
                const creditDoc = await t.get(creditRef);

                if (debitDoc.exists && creditDoc.exists) {
                    // IDEMPOTENCY SAFETY:
                    // If both entries exist, we have already processed this event.
                    // We must return explicitly to avoid duplicate writes.
                    // This handles cases where Eventarc delivers the same event multiple times (at-least-once delivery).
                    logger.info(`[IDEMPOTENCY] Ledger entries for transaction ${transactionId} already exist. Skipping duplicate processing.`);
                    return;
                }

                if (debitDoc.exists || creditDoc.exists) {
                    // PARTIAL STATE RECOVERY:
                    // If only one exists, the previous transaction likely failed mid-commit or we have data corruption.
                    // Strategy: We overwrite (upsert) both to ensure consistent state ("Repairing").
                    // Since ledger entries are immutable and determined by the transactionId, checking for partial existence
                    // and re-writing is safe and ensures eventual consistency.
                    logger.warn(`[RECOVERY] Partial ledger state detected for ${transactionId}. Repairing by overwriting entries.`);
                }

                // Create DEBIT Entry (Sender)
                const debitEntry: LedgerEntry = {
                    ledgerEntryId: debitEntryId,
                    transactionId: transactionId,
                    walletId: senderWalletId,
                    direction: 'DEBIT',
                    amount: amount,
                    currency: currency,
                    occurredAt: occurredAt, // Use event time, not processing time
                };

                // Create CREDIT Entry (Receiver)
                const creditEntry: LedgerEntry = {
                    ledgerEntryId: creditEntryId,
                    transactionId: transactionId,
                    walletId: receiverWalletId,
                    direction: 'CREDIT',
                    amount: amount,
                    currency: currency,
                    occurredAt: occurredAt,
                };

                t.set(debitRef, debitEntry);
                t.set(creditRef, creditEntry);
            });

            logger.info(`[LEDGER] Successfully recorded ledger entries`, {
                transactionId,
                debitEntryId,
                creditEntryId,
                amount,
                currency
            });
        } catch (error) {
            logger.error(`Failed to record ledger entries for ${transactionId}`, error);
            // Throwing ensures Eventarc retries the delivery
            throw error;
        }
    }
);
