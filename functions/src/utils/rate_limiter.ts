import * as admin from "firebase-admin";

const RATE_LIMIT_WINDOW_MS = 60 * 1000; // 1 minute
const MAX_TRANSFERS_PER_WINDOW = 10;

/**
 * Checks if the wallet has exceeded the transaction creation rate limit.
 * Uses the backend-authoritative 'events' collection to count recent attempts.
 * 
 * @param walletId The wallet ID attempting the transaction.
 * @throws Error if rate limit is exceeded.
 */
export async function checkTransferRateLimit(walletId: string): Promise<void> {
  const db = admin.firestore();
  const now = Date.now();
  const windowStart = new Date(now - RATE_LIMIT_WINDOW_MS).toISOString();

  // Query events to ensure we count actual attempts recognized by backend.
  // We look for 'transaction.created' events which map 1:1 to transfer attempts.
  const query = db.collection("events")
    .where("eventType", "==", "transaction.created")
    .where("senderWalletId", "==", walletId)
    .where("occurredAt", ">=", windowStart);

  // Use aggregation for cost efficiency and speed
  const snapshot = await query.count().get();
  const count = snapshot.data().count;

  if (count >= MAX_TRANSFERS_PER_WINDOW) {
    throw new Error(`Rate limit exceeded: Max ${MAX_TRANSFERS_PER_WINDOW} transfers per minute.`);
  }
}
