/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import {PublisherClient} from "@google-cloud/eventarc-publishing";
import {CloudEvent} from "cloudevents";
export { recordLedgerEntry } from "./ledger";

admin.initializeApp();
const db = admin.firestore();

// Initialize Eventarc Publisher Client
const publisherClient = new PublisherClient();

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
setGlobalOptions({ maxInstances: 10 });

const EMIT_EVENTS = true; // Feature flag for events

async function publishEvent(type: string, data: any, source: string) {
    if (!EMIT_EVENTS) return;
    
    // Construct the CloudEvent
    const cloudEvent = new CloudEvent({
        type: `com.boklo.wallet.${type}`,
        source: source,
        data: data,
        specversion: "1.0",
    });

    logger.info(`[Eventarc] Emitting ${cloudEvent.type}`, cloudEvent);
    
    // Publish to the default Eventarc channel
    // Note: Ensure the "Eventarc API" is enabled in your Google Cloud Project.
    // We strive to use the project ID from the environment.
    const projectId = process.env.GCLOUD_PROJECT || (process.env.FIREBASE_CONFIG ? JSON.parse(process.env.FIREBASE_CONFIG as string).projectId : "boklo-wallet");
    const location = "us-central1"; // Default location for Firebase Functions
    const channel = `projects/${projectId}/locations/${location}/channels/default`;

    try {
        await publisherClient.publishEvents({
            channel: channel,
            textEvents: [JSON.stringify(cloudEvent)]
        });
        logger.info(`[Eventarc] Successfully published to ${channel}`);
    } catch (e) {
        // We log error but do not fail the function execution to ensure idempotency/reliability of the core logic
        // In a strict event-driven system, we might want to retry or fail.
        logger.error(`[Eventarc] Failed to publish event ${type} to ${channel}`, e);
    }
}

export const onTransferCreated = onDocumentCreated("transfers/{transferId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
      logger.error("No data associated with the event");
      return;
  }

  const transferData = snapshot.data();
  const transferId = event.params.transferId;

  // Process only PENDING transfers
  if (transferData.status !== "pending") {
      logger.info(`Transfer ${transferId} is already ${transferData.status}, skipping.`);
      return;
  }

  // 1. Emit transaction.created
  await publishEvent("transaction.created", {
      transferId,
      amount: transferData.amount,
      currency: transferData.currency,
      fromWallet: transferData.fromWalletId,
      toWallet: transferData.toWalletId,
      timestamp: new Date().toISOString()
  }, `/transfers/${transferId}`);

  const { fromWalletId, toWalletId, amount } = transferData;
  const fromWalletRef = db.collection("wallets").doc(fromWalletId);
  const toWalletRef = db.collection("wallets").doc(toWalletId);
  const transferRef = snapshot.ref;

  // Transaction references
  const fromTxRef = fromWalletRef.collection("transactions").doc(`${transferId}_DEBIT`);
  const toTxRef = toWalletRef.collection("transactions").doc(`${transferId}_CREDIT`);

  try {
      await db.runTransaction(async (transaction) => {
          const fromWalletDoc = await transaction.get(fromWalletRef);
          const toWalletDoc = await transaction.get(toWalletRef);

          if (!fromWalletDoc.exists || !toWalletDoc.exists) {
              throw new Error("One or both wallets not found");
          }

          const fromBalance = fromWalletDoc.data()?.balance || 0;
          const toBalance = toWalletDoc.data()?.balance || 0;

          if (fromBalance < amount) {
              throw new Error("Insufficient balance");
          }

          const timestamp = admin.firestore.FieldValue.serverTimestamp();

          // Deduct from sender
          transaction.update(fromWalletRef, { balance: fromBalance - amount });
          transaction.set(fromTxRef, {
              id: fromTxRef.id,
              amount: amount,
              type: "debit",
              timestamp: timestamp,
              transferId: transferId,
          });

          // Add to recipient
          transaction.update(toWalletRef, { balance: toBalance + amount });
          transaction.set(toTxRef, {
              id: toTxRef.id,
              amount: amount,
              type: "credit",
              timestamp: timestamp,
              transferId: transferId,
          });

          // Update transfer status
          transaction.update(transferRef, { status: "completed" });
      });

      logger.info(`Transfer ${transferId} completed successfully.`);

      // 2. Emit transaction.completed
      await publishEvent("transaction.completed", {
          transferId,
          status: "completed",
          timestamp: new Date().toISOString()
      }, `/transfers/${transferId}`);

  } catch (error) {
      logger.error(`Transfer ${transferId} failed:`, error);
      
      const reason = error instanceof Error ? error.message : "Unknown error";

      // Update transfer status to FAILED
      await transferRef.update({ 
          status: "failed", 
          failureReason: reason
      });

      // 3. Emit transaction.failed
      await publishEvent("transaction.failed", {
          transferId,
          status: "failed",
          reason: reason,
          timestamp: new Date().toISOString()
      }, `/transfers/${transferId}`);
  }
});
