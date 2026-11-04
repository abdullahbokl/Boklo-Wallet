import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * Fee schedule, tunable via Remote Config:
 *  - transfer_fee_bps: fee in basis points applied to the amount
 *    (100 bps = 1%). 0 disables fees entirely (the default).
 *  - transfer_fee_free_below_minor: transfers at or below this amount
 *    (minor units) are always fee-free.
 */
const DEFAULT_FEE_BPS = 0;
const DEFAULT_FREE_BELOW_MINOR = 0;

const db = admin.firestore();

/** Result of computing the fee for an amount (all integer minor units). */
export interface FeeQuote {
    feeMinor: number;
    feeBps: number;
    freeBelowMinor: number;
}

/** Reads the fee schedule from Remote Config (falling back to defaults). */
export async function getFeeSchedule(): Promise<{
    feeBps: number;
    freeBelowMinor: number;
}> {
    try {
        const template = await admin.remoteConfig().getTemplate();
        const params = template.parameters;
        const parse = (key: string, fallback: number) => {
            const defaultValue = params[key]?.defaultValue;
            const raw =
                defaultValue && "value" in defaultValue
                    ? defaultValue.value
                    : undefined;
            const parsed = raw ? Number(raw) : NaN;
            return Number.isFinite(parsed) && parsed >= 0 ? parsed : fallback;
        };
        return {
            feeBps: parse("transfer_fee_bps", DEFAULT_FEE_BPS),
            freeBelowMinor: parse(
                "transfer_fee_free_below_minor",
                DEFAULT_FREE_BELOW_MINOR,
            ),
        };
    } catch (e) {
        logger.warn("Falling back to default fee schedule", {
            error: String(e),
        });
        return {
            feeBps: DEFAULT_FEE_BPS,
            freeBelowMinor: DEFAULT_FREE_BELOW_MINOR,
        };
    }
}

/**
 * Computes the fee for `amountMinor` under the schedule. Fees are rounded
 * half-up to whole minor units; sub-threshold amounts are always free.
 */
export function computeFeeMinor(
    amountMinor: number,
    feeBps: number,
    freeBelowMinor: number,
): number {
    if (feeBps <= 0) return 0;
    if (amountMinor <= freeBelowMinor) return 0;
    return Math.round((amountMinor * feeBps) / 10_000);
}

/**
 * Callable: quotes the fee for a prospective transfer amount so the client
 * can show it before confirmation. Authenticated caller only; the quote is
 * advisory — the authoritative fee is computed again inside the execution
 * transaction.
 */
export const estimateTransferFee = onCall(
    { region: "us-central1" },
    async (request) => {
        if (!request.auth) {
            throw new (require("firebase-functions/v2/https").HttpsError)(
                "unauthenticated",
                "Sign in to request a fee quote.",
            );
        }

        const amountMinor = Number(request.data?.amountMinor);
        if (!Number.isInteger(amountMinor) || amountMinor <= 0) {
            throw new (require("firebase-functions/v2/https").HttpsError)(
                "invalid-argument",
                "amountMinor must be a positive integer.",
            );
        }

        const schedule = await getFeeSchedule();
        const feeMinor = computeFeeMinor(
            amountMinor,
            schedule.feeBps,
            schedule.freeBelowMinor,
        );

        return {
            feeMinor,
            feeBps: schedule.feeBps,
            freeBelowMinor: schedule.freeBelowMinor,
        } satisfies FeeQuote;
    },
);

/**
 * Records the fee as a separate debit transaction + ledger entry inside
 * the execution transaction. Only called when feeMinor > 0.
 */
export function appendFeeEntries(
    t: admin.firestore.Transaction,
    opts: {
        transferId: string;
        fromWalletRef: admin.firestore.DocumentReference;
        feeMinor: number;
        currency: string;
        timestamp: admin.firestore.FieldValue;
    },
): void {
    const { transferId, fromWalletRef, feeMinor, currency, timestamp } = opts;

    t.update(fromWalletRef, {
        balance: admin.firestore.FieldValue.increment(-feeMinor),
        version: admin.firestore.FieldValue.increment(1),
    });

    const feeTxRef = fromWalletRef.collection("transactions").doc();
    t.set(feeTxRef, {
        id: feeTxRef.id,
        transferId: transferId,
        amount: feeMinor,
        type: "debit",
        counterpartyId: transferId,
        timestamp: timestamp,
        status: "completed",
        description: "Transfer fee",
    });

    const feeLedgerRef = db.collection("ledger").doc();
    t.set(feeLedgerRef, {
        transactionId: `${transferId}_fee`,
        senderWalletId: fromWalletRef.id,
        receiverWalletId: "PLATFORM_FEES",
        amount: feeMinor,
        currency,
        occurredAt: timestamp,
        idempotencyKey: `${transferId}_fee`,
    });
}
