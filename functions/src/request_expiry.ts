import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

/**
 * Scheduled sweep: payment requests older than 7 days that are still
 * PENDING are marked EXPIRED. acceptPaymentRequest only accepts PENDING,
 * so expired requests can no longer be fulfilled.
 */
export const expirePaymentRequests = onSchedule(
  {
    schedule: "every 24 hours",
    timeoutSeconds: 540,
  },
  async () => {
    const cutoff = Date.now() - 7 * 24 * 60 * 60 * 1000;
    const snapshot = await db
      .collection("payment_requests")
      .where("status", "==", "PENDING")
      .where("createdAt", "<=", new Date(cutoff))
      .get();

    if (snapshot.empty) {
      logger.info("Request expiry sweep found nothing to expire", {
        event: "REQUEST_EXPIRY_SWEEP",
        expired: 0,
      });
      return;
    }

    let expired = 0;
    for (let i = 0; i < snapshot.docs.length; i += 400) {
      const batch = db.batch();
      for (const doc of snapshot.docs.slice(i, i + 400)) {
        batch.update(doc.ref, {
          status: "EXPIRED",
          expiredAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        expired++;
      }
      await batch.commit();
    }

    logger.info("Request expiry sweep completed", {
      event: "REQUEST_EXPIRY_SWEEP",
      expired,
    });
  },
);
