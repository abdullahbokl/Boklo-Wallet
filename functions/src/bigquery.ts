import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from 'firebase-admin';
import * as logger from "firebase-functions/logger";
import { BigQuery } from "@google-cloud/bigquery";

// Initialize BigQuery client
const bigquery = new BigQuery();
const DATASET_ID = process.env.BIGQUERY_DATASET || "boklo_analytics";

// Helper for safe insertion
async function insertRows(tableId: string, rows: any[]) {
    try {
        await bigquery
            .dataset(DATASET_ID)
            .table(tableId)
            .insert(rows);
        logger.info(`BigQuery insert success: ${tableId}`, { count: rows.length });
    } catch (err: any) {
        // Analytical failures must not retry the trigger, but rows are
        // dead-lettered to Firestore so nothing is silently lost.
        const failedRows: Array<Record<string, unknown>> =
            err.name === 'PartialFailureError'
                ? err.errors?.map((e: { row?: unknown; reason?: string }) => ({
                    table: tableId,
                    reason: e.reason ?? 'partial_failure',
                    row: e.row,
                    failedAt: new Date(),
                })) ?? []
                : rows.map((row) => ({
                    table: tableId,
                    reason: String(err),
                    row,
                    failedAt: new Date(),
                }));
        const db = admin.firestore();
        for (const failed of failedRows) {
            await db.collection('bigquery_dead_letter').add(failed);
        }
        logger.error(`BigQuery insert failed; dead-lettered ${failedRows.length} row(s) for table ${tableId}`);
    }
}

// Stream Transfers (Global Intent Record)
export const streamTransferToBigQuery = onDocumentCreated("transfers/{transferId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const row = {
        transfer_id: event.params.transferId,
        from_wallet_id: data.fromWalletId,
        to_wallet_id: data.toWalletId,
        amount: Number(data.amount),
        currency: data.currency,
        status: data.status,
        // Use event time as reliable timestamp if document field is missing or sentinel
        timestamp: data.createdAt && typeof data.createdAt.toDate === 'function' ? data.createdAt.toDate().toISOString() : event.time,
        risk_level: data.riskAssessment?.riskLevel || 'UNKNOWN',
        ingest_time: new Date().toISOString()
    };

    await insertRows("transfers", [row]);
});

// Stream Ledger Entries (Financial Truth)
export const streamLedgerToBigQuery = onDocumentCreated("wallets/{walletId}/ledger/{entryId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const row = {
        entry_id: event.params.entryId,
        wallet_id: event.params.walletId,
        transfer_id: data.transactionId,
        amount: Number(data.amount),
        direction: data.direction,
        currency: data.currency || 'EGP',
        timestamp: data.occurredAt || event.time,
        ingest_time: new Date().toISOString()
    };

    await insertRows("ledger_entries", [row]);
});
