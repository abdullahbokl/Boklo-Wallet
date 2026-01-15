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

        // Define Ledger IDs deterministically for idempotency
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
                    logger.info(`Ledger entries for transaction ${transactionId} already exist. Skipping.`);
                    return;
                }

                if (debitDoc.exists || creditDoc.exists) {
                    // Partial state! This is bad, but re-writing shouldn't hurt if we set same data.
                    logger.warn(`Partial ledger state detected for ${transactionId}. Repairing.`);
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

            logger.info(`Successfully recorded ledger entries for transaction ${transactionId}`);
        } catch (error) {
            logger.error(`Failed to record ledger entries for ${transactionId}`, error);
            // Throwing ensures Eventarc retries the delivery
            throw error;
        }
    }
);
