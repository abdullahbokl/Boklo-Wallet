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
// import {EventarcClient} from "@google-cloud/eventarc";
import {CloudEvent} from "cloudevents";

admin.initializeApp();
const db = admin.firestore();

// Initialize Eventarc Client
// const eventarc = new EventarcClient();

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
    
    // We default to the global location and default channel in a real setup
    // For now, we construct the event. In a production Eventarc setup, 
    // we would publish to a specific channel.
    // Note: The Eventarc Node.js SDK 'publish' method requires a channel/location context.
    // If running in Cloud Functions locally or without explicit Eventarc setup, 
    // we might just log "Emitting Event" or skip actual API call to avoid errors if the API isn't enabled.
    
    // For this preparation step, we will verify we CAN construct the CloudEvent 
    // and log the intent. In a real deployment, we would await eventarc.channel(...).publish(...)
    
    const cloudEvent = new CloudEvent({
        type: `com.boklo.wallet.${type}`,
        source: source,
        data: data,
        specversion: "1.0",
    });

    logger.info(`[Eventarc] Emitting ${cloudEvent.type}`, cloudEvent);
    
    // START: Actual Eventarc publishing logic (commented out until infrastructure is ready)
    /*
    try {
        await eventarc.channel("projects/boklo-wallet/locations/us-central1/channels/default")
            .publish(cloudEvent);
    } catch (e) {
        logger.error(`Failed to publish event ${type}`, e);
    }
    */
    // END: Actual Eventarc publishing logic
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
