
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
const publishNotification = async (intent: NotificationIntent, transactionId: string) => {
    logger.info("Notification enqueue started", {
      event: "NOTIFICATION_ENQUEUE",
      status: "STARTED",
      transactionId: transactionId,
      notificationId: intent.notificationId,
      type: intent.type
    });

    const startTime = Date.now();
    const ref = db.collection("notifications").doc(intent.notificationId);
    
    try {
        await db.runTransaction(async (t) => {
            const doc = await t.get(ref);
            if (doc.exists) {
                // IDEMPOTENCY CHECK:
                // We use a deterministic ID (e.g., "{txId}_SENT") to ensure we only queue one notification
                // per event, even if the event is delivered multiple times.
                logger.info("Notification intent already queued (idempotency)", {
                  event: "NOTIFICATION_ENQUEUE",
                  status: "SKIPPED",
                  transactionId: transactionId,
                  notificationId: intent.notificationId,
                  reason: "Already exists"
                });
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
        logger.info("Notification enqueued successfully", {
          event: "NOTIFICATION_ENQUEUE",
          status: "COMPLETED",
          transactionId: transactionId,
          notificationId: intent.notificationId,
          durationMs: Date.now() - startTime
        });
    } catch (e) {
        logger.error("Notification enqueue failed", {
          event: "NOTIFICATION_ENQUEUE",
          status: "FAILED",
          transactionId: transactionId,
          notificationId: intent.notificationId,
          error: e,
          durationMs: Date.now() - startTime
        });
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
        }, payload.transactionId);

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
        }, payload.transactionId);
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
        }, payload.transactionId);
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

        // Attempt to extract transactionId (suffix removal)
        // notificationId format: {transactionId}_{SENT|RECEIVED|FAILED}
        const notificationId = event.params.notificationId;
        const transactionId = notificationId.replace(/_(SENT|RECEIVED|FAILED)$/, "");

        // IDEMPOTENCY / STATE CHECK:
        // Ensure we only process notifications that are strictly PENDING.
        // If status is SENT or FAILED, it means we (or a concurrent execution) already tried processing it.
        // This prevents double-sending if the function is re-triggered.
        if (notification.status !== 'PENDING') {
            logger.info("Notification delivery skipped", {
              event: "NOTIFICATION_DELIVERY",
              status: "SKIPPED",
              transactionId: transactionId,
              notificationId: notificationId,
              reason: `Status is ${notification.status}`
            });
            return;
        }

        logger.info("Notification delivery started", {
          event: "NOTIFICATION_DELIVERY",
          status: "STARTED",
          transactionId: transactionId,
          notificationId: notificationId,
          userId: notification.userId
        });
        
        const startTime = Date.now();
        
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

            logger.info("Notification delivery completed", {
              event: "NOTIFICATION_DELIVERY",
              status: "COMPLETED",
              transactionId: transactionId,
              notificationId: notificationId,
              successCount: response.successCount,
              failureCount: response.failureCount,
              durationMs: Date.now() - startTime
            });
            
        } catch (e) {
            logger.error("Notification delivery failed", {
              event: "NOTIFICATION_DELIVERY",
              status: "FAILED",
              transactionId: transactionId,
              notificationId: notificationId,
              error: e instanceof Error ? e.message : 'Unknown error',
              durationMs: Date.now() - startTime
            });
            await snapshot.ref.update({
                status: 'FAILED',
                error: e instanceof Error ? e.message : 'Unknown error'
            });
        }
    }
);
