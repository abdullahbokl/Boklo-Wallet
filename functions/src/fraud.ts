import { onCustomEventPublished } from "firebase-functions/v2/eventarc";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

// Ensure admin is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();

const HIGH_AMOUNT_THRESHOLD = 5000; // Example threshold
const VELOCITY_WINDOW_MINUTES = 60;
const VELOCITY_COUNT_THRESHOLD = 5;

export const detectFraud = onCustomEventPublished(
    "com.boklo.wallet.transaction.created",
    async (event) => {
        logger.info("Received transaction.created fraud check event", event.id);

        const eventData = event.data as any;
        const { transferId, fromWallet, amount, timestamp } = eventData;

        if (!transferId || !fromWallet || !amount) {
            logger.warn("Invalid event data for fraud check", eventData);
            return;
        }

        const alerts: string[] = [];

        // 1. High Amount Check
        if (amount > HIGH_AMOUNT_THRESHOLD) {
            alerts.push(`High amount transaction: ${amount}`);
        }

        // 2. Velocity Check (Simple implementation)
        // Check how many transfers this wallet created in the last window
        try {
            const windowStart = new Date(new Date(timestamp).getTime() - VELOCITY_WINDOW_MINUTES * 60000);
            
            // Note: This requires an index on (fromWalletId, createdAt)
            // If index is missing, this might fail or be slow. 
            // For now, we wrap in try-catch and log warning.
            
            // We use 'transfers' collection where we assume createdAt is stored as ISO string or timestamp
            // In the Flutter app, we store createdAt.
            
            const recentTransfers = await db.collection("transfers")
                .where("fromWalletId", "==", fromWallet)
                .where("createdAt", ">=", windowStart.toISOString()) 
                .count()
                .get();

            if (recentTransfers.data().count > VELOCITY_COUNT_THRESHOLD) {
                alerts.push(`High velocity: ${recentTransfers.data().count} transfers in ${VELOCITY_WINDOW_MINUTES}m`);
            }

        } catch (e) {
            logger.warn("Failed to perform velocity check (likely missing index)", e);
        }

        if (alerts.length > 0) {
            logger.warn(`[FRAUD ALERT] Suspicious activity detected for transfer ${transferId}: ${alerts.join(", ")}`);
            
            // Record alert
            await db.collection("fraud_alerts").add({
                transferId,
                fromWallet,
                amount,
                alerts,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                status: "investigating"
            });
        } else {
            logger.info(`Transfer ${transferId} passed fraud checks.`);
        }
    }
);
