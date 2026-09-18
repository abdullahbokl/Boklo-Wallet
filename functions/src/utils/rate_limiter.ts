import * as admin from "firebase-admin";

const RATE_LIMIT_WINDOW_MS = 60 * 1000; // 1 minute
const DEFAULT_MAX_TRANSFERS_PER_WINDOW = 10;

/** Remote-Config-tunable per-minute cap; falls back to the default. */
async function getMaxTransfersPerWindow(): Promise<number> {
  try {
    const template = await admin.remoteConfig().getTemplate();
    const raw = template.parameters["rate_limit_max_per_minute"]?.defaultValue;
    const value =
      raw && "value" in raw ? Number(raw.value) : NaN;
    return Number.isFinite(value) && value > 0
      ? value
      : DEFAULT_MAX_TRANSFERS_PER_WINDOW;
  } catch {
    return DEFAULT_MAX_TRANSFERS_PER_WINDOW;
  }
}

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

  const maxPerWindow = await getMaxTransfersPerWindow();
  if (count >= maxPerWindow) {
    throw new Error(`Rate limit exceeded: Max ${maxPerWindow} transfers per minute.`);
  }
}
