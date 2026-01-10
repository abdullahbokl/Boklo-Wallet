import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

const db = admin.firestore();

export const onTransferCreated = onDocumentCreated("transfers/{transferId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.error("No data associated with the event");
    return;
  }

  const transferData = snapshot.data();
  const transferId = event.params.transferId;

  // Idempotency / Guard: Process only PENDING transfers
  if (transferData.status !== "pending") {
    logger.info(`Transfer ${transferId} is already ${transferData.status}, skipping.`);
    return;
  }

  const { fromWalletId, toWalletId, amount } = transferData;
  const transferRef = snapshot.ref;

  // Validation: Sender != Receiver
  if (fromWalletId === toWalletId) {
    logger.error(`Transfer ${transferId} failed: Sender cannot be receiver`);
    await transferRef.update({ 
        status: "failed", 
        failureReason: "Sender cannot be receiver" 
    });
    return;
  }

  const fromWalletRef = db.collection("wallets").doc(fromWalletId);
  const toWalletRef = db.collection("wallets").doc(toWalletId);

  // Transaction references for history/ledger
  const fromTxRef = fromWalletRef.collection("transactions").doc(`${transferId}_DEBIT`);
  const toTxRef = toWalletRef.collection("transactions").doc(`${transferId}_CREDIT`);

  try {
    await db.runTransaction(async (transaction) => {
        const fromWalletDoc = await transaction.get(fromWalletRef);
        const toWalletDoc = await transaction.get(toWalletRef);

        // Validation: Wallets exist
        if (!fromWalletDoc.exists || !toWalletDoc.exists) {
            throw new Error("One or both wallets not found");
        }

        const fromBalance = fromWalletDoc.data()?.balance || 0;
        const toBalance = toWalletDoc.data()?.balance || 0;

        // Validation: Balance
        if (fromBalance < amount) {
            throw new Error("Insufficient balance");
        }

        const timestamp = admin.firestore.FieldValue.serverTimestamp();

        // 1. Deduct from sender
        transaction.update(fromWalletRef, { balance: fromBalance - amount });
        transaction.set(fromTxRef, {
            id: fromTxRef.id,
            amount: amount,
            type: "debit",
            timestamp: timestamp,
            transferId: transferId,
            description: `Transfer to ${toWalletId}`,
            status: "completed"
        });

        // 2. Credit receiver
        transaction.update(toWalletRef, { balance: toBalance + amount });
        transaction.set(toTxRef, {
            id: toTxRef.id,
            amount: amount,
            type: "credit",
            timestamp: timestamp,
            transferId: transferId,
            description: `Transfer from ${fromWalletId}`,
            status: "completed"
        });

        // 3. Update transfer status
        transaction.update(transferRef, { status: "completed" });
    });

    logger.info(`Transfer ${transferId} completed successfully.`);

  } catch (error) {
    logger.error(`Transfer ${transferId} failed:`, error);
    
    const reason = error instanceof Error ? error.message : "Unknown error";

    // Update transfer status to FAILED
    await transferRef.update({ 
        status: "failed", 
        failureReason: reason
    });
  }
});
