import { onMessagePublished } from "firebase-functions/v2/pubsub";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";

// Ensure admin is initialized (it might be initialized in index.ts, but safe to call if check is done or relying on single instance)
if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();

interface LedgerEntry {
    id: string; // Specific Ledger ID
    transferId: string;
    fromWalletId: string;
    toWalletId: string;
    amount: number;
    currency: string;
    timestamp: string; // ISO string from event
    recordedAt: FieldValue; // When it was written to ledger
    type: 'TRANSFER';
    metadata?: any;
}

export const recordLedgerEntry = onMessagePublished(
    {
        topic: "transaction-completed",
        retry: true,
    },
    async (event) => {
        logger.info("Received transaction.completed event for Ledger via Pub/Sub", event.id);

        let eventData = event.data.message.json;
        if (eventData && eventData.data) {
             eventData = eventData.data;
        }

        const { transferId, fromWallet, toWallet, amount, currency, timestamp } = eventData || {};

        if (!transferId || !amount) {
            logger.error("Invalid event data", eventData);
            return;
        }

        const ledgerRef = db.collection("ledger").doc(transferId);

        try {
            await db.runTransaction(async (transaction) => {
                const doc = await transaction.get(ledgerRef);
                if (doc.exists) {
                    logger.info(`Ledger entry for transfer ${transferId} already exists. Skipping.`);
                    return;
                }

                const entry: LedgerEntry = {
                    id: transferId, // 1:1 mapping for transfers for now
                    transferId,
                    fromWalletId: fromWallet,
                    toWalletId: toWallet,
                    amount,
                    currency: currency || "SAR", // Default if missing
                    timestamp,
                    recordedAt: FieldValue.serverTimestamp(),
                    type: "TRANSFER",
                    metadata: {
                        eventId: event.id,
                        source: event.source,
                    }
                };

                transaction.set(ledgerRef, entry);
            });
            logger.info(`Ledger entry created for transfer ${transferId}`);
        } catch (error) {
            logger.error(`Failed to create ledger entry for ${transferId}`, error);
            // Throwing error prompts Pub/Sub retry mechanism
            throw error;
        }
    }
);
