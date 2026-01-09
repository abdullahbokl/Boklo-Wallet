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

admin.initializeApp();
const db = admin.firestore();

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
setGlobalOptions({ maxInstances: 10 });

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
  } catch (error) {
      logger.error(`Transfer ${transferId} failed:`, error);
      
      // Update transfer status to FAILED
      await transferRef.update({ 
          status: "failed", 
          failureReason: error instanceof Error ? error.message : "Unknown error" 
      });
  }
});
