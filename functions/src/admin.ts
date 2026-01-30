import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

/**
 * Triggered when a document is created in 'admin_jobs' collection.
 * Supports:
 * - REPLAY_TRANSACTION_EVENTS: Scans transfers in range and re-creates missing transaction.created events.
 */
export const onAdminJobCreated = onDocumentCreated("admin_jobs/{jobId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const jobData = snapshot.data();
    const jobId = event.params.jobId;

    if (jobData.type !== "REPLAY_TRANSACTION_EVENTS") {
        logger.info(`Ignoring unknown job type: ${jobData.type}`);
        return; // Or mark as SKIPPED
    }

    const { fromDate, toDate, dryRun } = jobData;

    try {
        await db.collection("admin_jobs").doc(jobId).update({ status: "RUNNING", startTime: admin.firestore.FieldValue.serverTimestamp() });

        const transactionsSnapshot = await db.collection("transfers")
            .where("createdAt", ">=", new Date(fromDate))
            .where("createdAt", "<=", new Date(toDate))
            .get();

        logger.info(`Job ${jobId}: Found ${transactionsSnapshot.size} transactions to check for replay.`);

        let replayedCount = 0;

        for (const doc of transactionsSnapshot.docs) {
            const data = doc.data();
            const txId = doc.id;

            // Check if events exist (using deterministic ID pattern from transfers.ts)
            const createdEventId = `${txId}_created`;
            const eventDoc = await db.collection("events").doc(createdEventId).get();

            if (!eventDoc.exists) {
                replayedCount++;
                logger.info(`Job ${jobId}: Missing event for transfer ${txId}. Replaying...`);
                
                if (!dryRun) {
                    await db.collection("events").doc(createdEventId).set({
                        eventId: createdEventId,
                        eventType: "transaction.created",
                        // Use original timestamp if available, else job time
                        occurredAt: data.createdAt && typeof data.createdAt.toDate === 'function' ? data.createdAt.toDate().toISOString() : new Date().toISOString(),
                        transactionId: txId,
                        senderWalletId: data.fromWalletId,
                        receiverWalletId: data.toWalletId,
                        amount: data.amount,
                        currency: data.currency,
                        replayed: true,
                        replayedJobId: jobId
                    });
                }
            }
        }

        await db.collection("admin_jobs").doc(jobId).update({
            status: "COMPLETED",
            replayedCount,
            dryRun: !!dryRun,
            endTime: admin.firestore.FieldValue.serverTimestamp()
        });
        
        logger.info(`Job ${jobId}: Completed. Replayed ${replayedCount} events.`);

    } catch (error: any) {
        logger.error(`Admin job failed`, error);
        await db.collection("admin_jobs").doc(jobId).update({
            status: "FAILED",
            error: error.message,
            endTime: admin.firestore.FieldValue.serverTimestamp()
        });
    }
});
