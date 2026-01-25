
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

// Initialize admin if not already done
if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();

/**
 * Scheduled Reconciliation Job
 * Runs every day at midnight.
 * 
 * Purpose:
 * - Scan all wallets.
 * - For each wallet, sum up all ledger entries in `wallets/{walletId}/ledger`.
 * - Compare the calculated sum with `wallets/{walletId}.balance`.
 * - Log any discrepancies for manual review.
 * 
 * NOTE: This job is READ-ONLY. It does not auto-fix balances to prevent
 * accidental mass-corruption if logic is flawed.
 */
export const reconcileWallets = onSchedule("every day 00:00", async (event) => {
    logger.info("Reconciliation job started", {
        event: "RECONCILIATION_JOB",
        status: "STARTED"
    });

    const startTime = Date.now();
    let verifiedCount = 0;
    let mismatchCount = 0;
    let errorCount = 0;

    try {
        const walletsSnapshot = await db.collection("wallets").get();
        logger.info(`Found ${walletsSnapshot.size} wallets to reconcile.`);

        for (const walletDoc of walletsSnapshot.docs) {
            const walletId = walletDoc.id;
            const currentBalance = walletDoc.data().balance || 0;
            const currency = walletDoc.data().currency || 'USD';

            try {
                // Calculate balance from ledger (Source of Truth)
                const ledgerSnapshot = await db
                    .collection("wallets")
                    .doc(walletId)
                    .collection("ledger")
                    .get();

                let calculatedBalance = 0;
                ledgerSnapshot.forEach(doc => {
                    const data = doc.data();
                    const amount = Number(data.amount) || 0;
                    if (data.direction === 'CREDIT') {
                        calculatedBalance += amount;
                    } else if (data.direction === 'DEBIT') {
                        calculatedBalance -= amount;
                    }
                });

                // Round to avoid floating point precision issues
                // calculatedBalance = Math.round(calculatedBalance * 100) / 100;

                // Compare
                // We allow a very small epsilon for floating point math
                const diff = Math.abs(currentBalance - calculatedBalance);
                
                if (diff > 0.001) {
                    mismatchCount++;
                    logger.error(`Balance mismatch detected`, {
                        event: "RECONCILIATION_MISMATCH",
                        walletId: walletId,
                        currentBalance: currentBalance,
                        calculatedBalance: calculatedBalance,
                        difference: currentBalance - calculatedBalance,
                        currency: currency
                    });
                } else {
                    verifiedCount++;
                }

            } catch (walletError) {
                errorCount++;
                logger.error(`Failed to reconcile wallet ${walletId}`, {
                    event: "RECONCILIATION_ERROR",
                    walletId: walletId,
                    error: walletError instanceof Error ? walletError.message : String(walletError)
                });
            }
        }

        logger.info("Reconciliation job completed", {
            event: "RECONCILIATION_JOB",
            status: "COMPLETED",
            durationMs: Date.now() - startTime,
            totalWallets: walletsSnapshot.size,
            verifiedWithNoIssues: verifiedCount,
            mismatchesFound: mismatchCount,
            errorsChecking: errorCount
        });

    } catch (e) {
        logger.error("Reconciliation job failed fatally", {
            event: "RECONCILIATION_JOB",
            status: "FAILED",
            error: e instanceof Error ? e.message : String(e),
            durationMs: Date.now() - startTime
        });
    }
});
