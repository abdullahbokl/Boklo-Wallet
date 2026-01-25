
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

export async function runConnectivityCheck(
    db: admin.firestore.Firestore,
    transactionId: string,
    senderWalletId: string,
    receiverWalletId: string,
    amount: number,
    currency: string
) {
    logger.info("Starting ledger consistency check", { transactionId });

    try {
        // 1. Verify Ledger Entries
        const debitEntryId = `${transactionId}_DR`;
        const creditEntryId = `${transactionId}_CR`;

        const ledgerRefs = await db.getAll(
            db.collection("ledger").doc(debitEntryId),
            db.collection("ledger").doc(creditEntryId)
        );

        const [debitDoc, creditDoc] = ledgerRefs;

        if (!debitDoc.exists) {
            logger.warn(`Consistency Check Failed: Missing Debit Ledger Entry`, { transactionId, entryId: debitEntryId });
        }
        if (!creditDoc.exists) {
            logger.warn(`Consistency Check Failed: Missing Credit Ledger Entry`, { transactionId, entryId: creditEntryId });
        }

        // 2. Verify Wallet Transaction Records (The "Delta")
        // Since we don't know the auto-generated IDs of the transaction docs in the subcollections,
        // we must query by transferId/transactionId.
        
        // Sender Match
        const senderTxSnapshot = await db.collection(`wallets/${senderWalletId}/transactions`)
            .where("transferId", "==", transactionId)
            .limit(1)
            .get();

        if (senderTxSnapshot.empty) {
             logger.warn(`Consistency Check Failed: Missing Sender Transaction Record`, { transactionId, walletId: senderWalletId });
        } else {
            const data = senderTxSnapshot.docs[0].data();
            if (data.amount !== amount) {
                logger.warn(`Consistency Check Failed: Sender Amount Mismatch`, { 
                    transactionId, 
                    walletId: senderWalletId, 
                    expected: amount, 
                    actual: data.amount 
                });
            }
        }

        // Receiver Match
        const receiverTxSnapshot = await db.collection(`wallets/${receiverWalletId}/transactions`)
            .where("transferId", "==", transactionId)
            .limit(1)
            .get();

        if (receiverTxSnapshot.empty) {
             logger.warn(`Consistency Check Failed: Missing Receiver Transaction Record`, { transactionId, walletId: receiverWalletId });
        } else {
            const data = receiverTxSnapshot.docs[0].data();
            if (data.amount !== amount) {
                logger.warn(`Consistency Check Failed: Receiver Amount Mismatch`, { 
                    transactionId, 
                    walletId: receiverWalletId, 
                    expected: amount, 
                    actual: data.amount 
                });
            }
        }
        
        logger.info("Consistency check completed", { transactionId });

    } catch (error) {
        logger.warn("Consistency check encountered an error", { transactionId, error });
    }
}
