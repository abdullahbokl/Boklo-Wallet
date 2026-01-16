
import { onCustomEventPublished } from "firebase-functions/v2/eventarc";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { TransferEventType, TransactionCompletedEvent, TransactionFailedEvent } from "./domain/events/transfer_events";
import { NotificationType, NotificationIntent } from "./domain/notifications/notification_intent";

if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();

// Helper to write notification intent to Firestore idempotently
const publishNotification = async (intent: NotificationIntent) => {
    const ref = db.collection("notifications").doc(intent.notificationId);
    
    try {
        await db.runTransaction(async (t) => {
            const doc = await t.get(ref);
            if (doc.exists) {
                logger.info(`Notification ${intent.notificationId} already exists. Skipping.`);
                return;
            }
            
            // In a real app, we might look up userId from walletId here if they differ.
            // For now, we assume the walletId maps directly or is sufficient for the push service.
            
            t.set(ref, {
                ...intent,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                status: 'PENDING'
            });
        });
        logger.info(`Queued notification: ${intent.notificationId} (${intent.type})`);
    } catch (e) {
        logger.error(`Failed to publish notification ${intent.notificationId}`, e);
        throw e; // Ensure retry
    }
};

export const notifyOnTransferComplete = onCustomEventPublished(
    {
        eventType: TransferEventType.COMPLETED,
        retry: true,
    },
    async (event) => {
        const payload = event.data as unknown as TransactionCompletedEvent;
        if (!payload?.transactionId) {
            logger.error("Invalid completion event payload", payload);
            return;
        }

        // 1. Notify Sender (Success)
        await publishNotification({
            notificationId: `${payload.transactionId}_SENT`,
            userId: payload.senderWalletId,
            type: NotificationType.TRANSFER_SENT_SUCCESS,
            payload: {
                titleKey: 'transfer_sent_success_title',
                bodyKey: 'transfer_sent_success_body',
                data: { 
                    amount: payload.amount.toString(), 
                    currency: payload.currency 
                }
            }
        });

        // 2. Notify Receiver (Received)
        await publishNotification({
            notificationId: `${payload.transactionId}_RECEIVED`,
            userId: payload.receiverWalletId,
            type: NotificationType.TRANSFER_RECEIVED,
            payload: {
                titleKey: 'transfer_received_title',
                bodyKey: 'transfer_received_body',
                data: { 
                    amount: payload.amount.toString(), 
                    currency: payload.currency 
                }
            }
        });
    }
);

export const notifyOnTransferFailed = onCustomEventPublished(
    {
        eventType: TransferEventType.FAILED,
        retry: true,
    },
    async (event) => {
        const payload = event.data as unknown as TransactionFailedEvent;
        if (!payload?.transactionId) {
            logger.error("Invalid failure event payload", payload);
            return;
        }

        // Notify Sender (Failure)
        await publishNotification({
            notificationId: `${payload.transactionId}_FAILED`,
            userId: payload.senderWalletId,
            type: NotificationType.TRANSFER_FAILED,
            payload: {
                titleKey: 'transfer_failed_title',
                bodyKey: 'transfer_failed_body',
                data: { 
                    reason: payload.failureReason 
                }
            }
        });
    }
);

// [NEW] Delivery Mechanism
// Triggers when a new notification intent is written to Firestore.
// In a real system, this would fetch FCM tokens and send the message.
import { onDocumentCreated } from "firebase-functions/v2/firestore";

export const onNotificationQueued = onDocumentCreated(
    "notifications/{notificationId}",
    async (event) => {
        const snapshot = event.data;
        if (!snapshot) {
            return;
        }

        const notification = snapshot.data() as NotificationIntent & { status: string };

        // Idempotency / State Check
        if (notification.status !== 'PENDING') {
            return;
        }

        logger.info(`[DELIVERY] Processing notification ${event.params.notificationId} for user ${notification.userId}`);
        
        try {
            // SIMULATION: FCM Delivery
            // data: { ...notification.payload }
            logger.info(`[DELIVERY] FCM Message Sent (Simulated):`, {
                to: notification.userId,
                title: notification.payload.titleKey,
                body: notification.payload.bodyKey,
                data: notification.payload.data
            });

            // Update status to SENT
            await snapshot.ref.update({
                status: 'SENT',
                sentAt: admin.firestore.FieldValue.serverTimestamp()
            });
            
        } catch (e) {
            logger.error(`[DELIVERY] Failed to send notification ${event.params.notificationId}`, e);
            await snapshot.ref.update({
                status: 'FAILED',
                error: e instanceof Error ? e.message : 'Unknown error'
            });
        }
    }
);
