import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

type Frequency = "daily" | "weekly" | "monthly";

interface ScheduledTransferDoc {
    fromWalletId: string;
    toWalletId: string;
    amount: number; // integer minor units
    currency: string;
    note?: string;
    frequency: Frequency;
    nextRunAt: admin.firestore.Timestamp;
    endDate?: admin.firestore.Timestamp | null;
    status: "ACTIVE" | "PAUSED" | "CANCELLED" | "COMPLETED";
    createdAt?: admin.firestore.FieldValue;
    lastRunAt?: admin.firestore.Timestamp | null;
    lastError?: string | null;
    runCount?: number;
    minorUnits?: boolean;
}

function assertPositiveIntegerAmount(amount: unknown): amount is number {
    return typeof amount === "number" && Number.isInteger(amount) && amount > 0;
}

function isFrequency(value: unknown): value is Frequency {
    return value === "daily" || value === "weekly" || value === "monthly";
}

/** Next run timestamp strictly after `from`, honoring the frequency. */
export function nextRunAfter(
    from: Date,
    frequency: Frequency,
): Date {
    const next = new Date(from);
    switch (frequency) {
        case "daily":
            next.setUTCDate(next.getUTCDate() + 1);
            break;
        case "weekly":
            next.setUTCDate(next.getUTCDate() + 7);
            break;
        case "monthly":
            // JS normalizes overflow (Jan 31 -> Mar 3); clamp back to the
            // last day of the expected month.
            const expectedMonth = next.getUTCMonth() + 1;
            next.setUTCMonth(expectedMonth);
            if (next.getUTCMonth() !== ((expectedMonth % 12) + 12) % 12) {
                next.setUTCDate(0); // last day of previous (intended) month
            }
            break;
    }
    return next;
}

/**
 * Callable: creates a recurring transfer. The recipient must be an
 * existing wallet id; amount is integer minor units. Authenticated
 * caller only; the schedule runs under the caller's wallet.
 */
export const createScheduledTransfer = onCall(
    { region: "us-central1" },
    async (request) => {
        const uid = request.auth?.uid;
        if (!uid) {
            throw new HttpsError("unauthenticated", "Sign in first.");
        }

        const data = request.data ?? {};
        const toWalletId = typeof data.toWalletId === "string" ? data.toWalletId : "";
        const currency = typeof data.currency === "string" ? data.currency : "";
        const note = typeof data.note === "string" ? data.note.slice(0, 200) : undefined;
        const frequency = data.frequency;

        if (!toWalletId || !isFrequency(frequency)) {
            throw new HttpsError(
                "invalid-argument",
                "toWalletId and frequency (daily|weekly|monthly) are required.",
            );
        }
        if (!assertPositiveIntegerAmount(data.amount)) {
            throw new HttpsError(
                "invalid-argument",
                "amount must be a positive integer of minor units.",
            );
        }
        if (toWalletId === uid) {
            throw new HttpsError(
                "invalid-argument",
                "Cannot schedule a transfer to yourself.",
            );
        }

        // The recipient wallet must exist and match the sender's currency;
        // the executor re-verifies everything at run time.
        const toWallet = await db.collection("wallets").doc(toWalletId).get();
        if (!toWallet.exists) {
            throw new HttpsError("not-found", "Recipient wallet not found.");
        }
        if (toWallet.data()?.currency !== currency) {
            throw new HttpsError(
                "failed-precondition",
                "Scheduled transfers require matching currencies.",
            );
        }

        const doc: ScheduledTransferDoc = {
            fromWalletId: uid,
            toWalletId,
            amount: data.amount,
            currency,
            note,
            frequency,
            nextRunAt: admin.firestore.Timestamp.fromDate(new Date()),
            status: "ACTIVE",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            lastRunAt: null,
            lastError: null,
            runCount: 0,
            minorUnits: true,
        };

        const ref = await db.collection("scheduled_transfers").add(doc);
        logger.info("Scheduled transfer created", {
            id: ref.id,
            uid,
            frequency,
        });
        return { id: ref.id };
    },
);

/**
 * Callable: cancels one of the caller's schedules (owner-gated).
 */
export const cancelScheduledTransfer = onCall(
    { region: "us-central1" },
    async (request) => {
        const uid = request.auth?.uid;
        if (!uid) {
            throw new HttpsError("unauthenticated", "Sign in first.");
        }
        const id = request.data?.id;
        if (typeof id !== "string" || id.length === 0) {
            throw new HttpsError("invalid-argument", "id is required.");
        }

        const ref = db.collection("scheduled_transfers").doc(id);
        const doc = await ref.get();
        if (!doc.exists || doc.data()?.fromWalletId !== uid) {
            throw new HttpsError("not-found", "Schedule not found.");
        }

        await ref.update({ status: "CANCELLED" });
        return { cancelled: true };
    },
);

/**
 * Hourly sweep: due ACTIVE schedules each spawn a standard `transfers`
 * document (the existing idempotent executor handles it), then advance
 * nextRunAt or complete the schedule past its endDate. Transfer failures
 * do not kill the schedule — the error is recorded and the next run is
 * still scheduled.
 */
export const processScheduledTransfers = onSchedule(
    {
        schedule: "every 60 minutes",
        region: "us-central1",
        timeoutSeconds: 540,
    },
    async () => {
        const now = admin.firestore.Timestamp.now();
        const due = await db
            .collection("scheduled_transfers")
            .where("status", "==", "ACTIVE")
            .where("nextRunAt", "<=", now)
            .limit(200)
            .get();

        if (due.empty) return;

        for (const doc of due.docs) {
            const s = doc.data() as ScheduledTransferDoc;
            try {
                const transferId = `sched_${doc.id}_${now.toMillis()}`;
                await db.collection("transfers").doc(transferId).set({
                    id: transferId,
                    fromWalletId: s.fromWalletId,
                    toWalletId: s.toWalletId,
                    amount: s.amount,
                    currency: s.currency,
                    status: "pending",
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    note: s.note ?? "Scheduled transfer",
                    minorUnits: true,
                });

                const next = nextRunAfter(now.toDate(), s.frequency);
                const pastEnd = s.endDate != null && next >= s.endDate.toDate();
                await doc.ref.update({
                    nextRunAt: admin.firestore.Timestamp.fromDate(next),
                    lastRunAt: now,
                    lastError: null,
                    runCount: (s.runCount ?? 0) + 1,
                    status: pastEnd ? "COMPLETED" : "ACTIVE",
                });
            } catch (e) {
                logger.error("Scheduled transfer run failed", {
                    id: doc.id,
                    error: String(e),
                });
                // Record and retry next sweep; the schedule stays ACTIVE.
                await doc.ref.update({
                    lastError: String(e),
                    nextRunAt: admin.firestore.Timestamp.fromDate(
                        nextRunAfter(now.toDate(), s.frequency),
                    ),
                });
            }
        }
    },
);
