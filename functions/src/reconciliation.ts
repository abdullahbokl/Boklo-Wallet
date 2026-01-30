
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
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();

/**
 * Core Reconciliation Logic
 * Reusable by both Schedule and HTTP trigger.
 */
async function runReconciliationLogic() {
    const startTime = Date.now();
    let verifiedCount = 0;
    let mismatchCount = 0;
    let errorCount = 0;
    const mismatches: any[] = []; // Typed slightly better in real code

    try {
        const walletsSnapshot = await db.collection("wallets").get();
        const totalWallets = walletsSnapshot.size;
        
        logger.info(`Starting reconciliation for ${totalWallets} wallets...`);

        for (const walletDoc of walletsSnapshot.docs) {
            const walletId = walletDoc.id;
            const data = walletDoc.data();
            const currentBalance = data.balance || 0;
            const currency = data.currency || 'USD';

            try {
                // Calculate balance from ledger (Source of Truth)
                const ledgerSnapshot = await db
                    .collection("wallets")
                    .doc(walletId)
                    .collection("ledger")
                    .get();

                let calculatedBalance = 0;
                ledgerSnapshot.forEach(doc => {
                    const entry = doc.data();
                    const amount = Number(entry.amount) || 0;
                    if (entry.direction === 'CREDIT') {
                        calculatedBalance += amount;
                    } else if (entry.direction === 'DEBIT') {
                        calculatedBalance -= amount;
                    }
                });

                // Compare with epsilon
                const diff = Math.abs(currentBalance - calculatedBalance);
                
                if (diff > 0.001) {
                    mismatchCount++;
                    logger.error(`Balance mismatch detected`, {
                        event: "RECONCILIATION_MISMATCH",
                        walletId,
                        expected: calculatedBalance,
                        actual: currentBalance,
                        diff
                    });
                    
                    if (mismatches.length < 10) {
                        mismatches.push({
                            walletId,
                            currentBalance,
                            calculatedBalance,
                            diff,
                            currency
                        });
                    }
                } else {
                    verifiedCount++;
                }

            } catch (walletError) {
                errorCount++;
                logger.error(`Failed to reconcile wallet ${walletId}`, { error: walletError });
            }
        }

        const status = mismatchCount > 0 ? "WARNING" : (errorCount > 0 ? "WARNING" : "SUCCESS");

        // Write Report
        const reportId = new Date().toISOString().split('T')[0];
        const reportData = {
            date: reportId,
            status,
            totalWallets,
            checkedWalletCount: totalWallets, // Synonymous here
            verifiedCount,
            mismatchCount,
            mismatchedWalletCount: mismatchCount, // Alias for clarity
            errorCount,
            sampleMismatches: mismatches,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            durationMs: Date.now() - startTime
        };

        await db.collection("reconciliation_reports").doc(reportId).set(reportData);

        logger.info("Reconciliation run completed", {
            event: "reconciliation.run",
            dateKey: reportId,
            checkedWalletCount: totalWallets,
            mismatchedWalletCount: mismatchCount,
            status
        });

        return reportData;

    } catch (e: any) {
        logger.error("Reconciliation run failed fatally", { error: e.message });
        throw e;
    }
}

/**
 * Scheduled Job: Daily Midnight
 */
export const reconcileWallets = onSchedule("every day 00:00", async (event) => {
    await runReconciliationLogic();
});

/**
 * HTTP Trigger: Manual Run (DEV/Admin Only)
 */
export const triggerReconciliationNow = onRequest(async (req, res) => {
    // Basic security check: Only allow if explicitly enabled or mostly for dev
    // In production, you'd check req.auth or specialized header/token.
    // For this task, we assume the caller has IAM permission to invoke the function.
    
    try {
        const report = await runReconciliationLogic();
        res.status(200).json({ 
            message: "Reconciliation triggered successfully", 
            report 
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});
