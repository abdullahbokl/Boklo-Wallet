
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
                // IDEMPOTENCY CHECK:
                // We use a deterministic ID (e.g., "{txId}_SENT") to ensure we only queue one notification
                // per event, even if the event is delivered multiple times.
                logger.info(`[IDEMPOTENCY] Notification ${intent.notificationId} already queued. Skipping.`);
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

        // IDEMPOTENCY / STATE CHECK:
        // Ensure we only process notifications that are strictly PENDING.
        // If status is SENT or FAILED, it means we (or a concurrent execution) already tried processing it.
        // This prevents double-sending if the function is re-triggered.
        if (notification.status !== 'PENDING') {
            logger.info(`[IDEMPOTENCY] Notification ${event.params.notificationId} is ${notification.status}. Skipping.`);
            return;
        }

        logger.info(`[DELIVERY] Processing notification ${event.params.notificationId} for user ${notification.userId}`);
        
        try {
            // Fetch Tokens
            const tokensSnapshot = await admin.firestore()
                .collection('users')
                .doc(notification.userId)
                .collection('tokens')
                .get();

            if (tokensSnapshot.empty) {
                logger.warn(`[DELIVERY] No tokens found for user ${notification.userId}`);
                await snapshot.ref.update({
                    status: 'SKIPPED_NO_TOKENS',
                    processedAt: admin.firestore.FieldValue.serverTimestamp()
                });
                return;
            }

            const tokens = tokensSnapshot.docs.map(d => d.data().token as string);
            
            
            // Helper for basic localization (MVP)
            const resolveText = (key: string, data: Record<string, string> = {}): string => {
                const map: Record<string, string> = {
                    'transfer_sent_success_title': 'Transfer Sent',
                    'transfer_sent_success_body': 'You sent {amount} {currency}.',
                    'transfer_received_title': 'Money Received',
                    'transfer_received_body': 'You received {amount} {currency}.',
                    'transfer_failed_title': 'Transfer Failed',
                    'transfer_failed_body': 'Your transfer failed. {reason}',
                };
                let text = map[key] || key;
                // Replace params
                for (const [k, v] of Object.entries(data)) {
                    text = text.replace(`{${k}}`, v);
                }
                return text;
            };

            // Send Multicast
            const message: admin.messaging.MulticastMessage = {
                tokens: tokens,
                notification: {
                    title: resolveText(notification.payload.titleKey, notification.payload.data),
                    body: resolveText(notification.payload.bodyKey, notification.payload.data),
                },
                data: notification.payload.data,
            };

            const response = await admin.messaging().sendEachForMulticast(message);
            
            logger.info(`[DELIVERY] FCM Response: ${response.successCount} succeded, ${response.failureCount} failed.`);

            // Handle invalid tokens
            if (response.failureCount > 0) {
                const invalidTokens: string[] = [];
                response.responses.forEach((resp, idx) => {
                    if (!resp.success && (
                        resp.error?.code === 'messaging/registration-token-not-registered' ||
                        resp.error?.code === 'messaging/invalid-registration-token'
                    )) {
                        invalidTokens.push(tokens[idx]);
                    }
                });

                if (invalidTokens.length > 0) {
                    logger.info(`[DELIVERY] Cleaning up ${invalidTokens.length} invalid tokens.`);
                    const batch = db.batch();
                    invalidTokens.forEach(t => {
                        const tokenRef = db.collection('users').doc(notification.userId).collection('tokens').doc(t);
                        batch.delete(tokenRef);
                    });
                    await batch.commit();
                }
            }

            // Update status to SENT
            await snapshot.ref.update({
                status: 'SENT',
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
                successCount: response.successCount,
                failureCount: response.failureCount
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
