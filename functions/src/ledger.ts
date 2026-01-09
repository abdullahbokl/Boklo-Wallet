import { onCustomEventPublished } from "firebase-functions/v2/eventarc";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

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
    recordedAt: admin.firestore.FieldValue; // When it was written to ledger
    type: 'TRANSFER';
    metadata?: any;
}

export const recordLedgerEntry = onCustomEventPublished(
    "com.boklo.wallet.transaction.completed",
    async (event) => {
        logger.info("Received transaction.completed event", event);

        const eventData = event.data as any; // Cast generic data
        const { transferId, fromWallet, toWallet, amount, currency, timestamp } = eventData;

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
                    recordedAt: admin.firestore.FieldValue.serverTimestamp(),
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
            // Throwing error prompts Eventarc/Functions to retry if configured
            throw error;
        }
    }
);
