import { onMessagePublished } from "firebase-functions/v2/pubsub";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

// Ensure admin is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}
// const db = admin.firestore();

async function sendNotification(userId: string, title: string, body: string) {
    // Placeholder for FCM / Email logic
    // In a real app, we would look up the user's FCM token from Firestore
    // and use admin.messaging().send(...)
    logger.info(`[Notification] To User: ${userId} | Title: ${title} | Body: ${body}`);
}

export const onTransactionCompletedNotification = onMessagePublished(
    {
        topic: "transaction-completed",
        retry: true,
    },
    async (event) => {
        logger.info("Received transaction.completed notification event via Pub/Sub", event.id);

        let eventData = event.data.message.json;
        if (eventData && eventData.data) {
             eventData = eventData.data;
        }
        
        const { transferId, fromWallet, toWallet, amount, currency } = eventData || {};

        if (!transferId || !amount) {
             logger.warn("Invalid event data for notification", eventData);
             return;
        }

        logger.info(`Processing completion notification for ${transferId}`);

        // Notify Sender
        await sendNotification(
            fromWallet, 
            "Transfer Successful", 
            `You sent ${amount} ${currency} successfully.`
        );

        // Notify Recipient
        await sendNotification(
            toWallet, 
            "Money Received", 
            `You received ${amount} ${currency}.`
        );
    }
);

export const onTransactionFailedNotification = onMessagePublished(
    {
        topic: "transaction-failed",
        retry: true,
    },
    async (event) => {
        logger.info("Received transaction.failed notification event via Pub/Sub", event.id);

        let eventData = event.data.message.json;
        if (eventData && eventData.data) {
             eventData = eventData.data;
        }

        const { transferId, fromWallet, amount, currency, reason } = eventData || {};

        logger.info(`Processing failure notification for ${transferId}`);

        if (fromWallet) {
             // Notify Sender
            await sendNotification(
                fromWallet, 
                "Transfer Failed", 
                `Your transfer of ${amount} ${currency} failed. Reason: ${reason}`
            );
        } else {
            logger.warn(`Cannot notify sender for failed transfer ${transferId}: fromWallet missing`);
        }
    }
);
