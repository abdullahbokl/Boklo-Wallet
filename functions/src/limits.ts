import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { Timestamp } from "@google-cloud/firestore";

const db = admin.firestore();

// Same defaults as fraud.ts (integer minor units). Remote Config can tune
// fraud thresholds independently; these surface the same values to users.
const DEFAULT_SINGLE_LIMIT_MINOR = 500_000;
const DEFAULT_DAILY_LIMIT_MINOR = 1_000_000;

/**
 * Callable: exposes the sender's current transfer limits so the client can
 * show headroom before sending. Authenticated caller only; limits apply to
 * the caller's own wallet (wallet id == uid).
 */
export const getTransferLimits = onCall(
  { region: "us-central1" },
  async (request) => {
    if (!request.auth) {
      throw new (require("firebase-functions/v2/https").HttpsError)(
        "unauthenticated",
        "Must be authenticated",
      );
    }
    const uid = request.auth.uid;

    let singleLimit = DEFAULT_SINGLE_LIMIT_MINOR;
    let dailyLimit = DEFAULT_DAILY_LIMIT_MINOR;
    try {
      const rc = admin.remoteConfig();
      const template = await rc.getTemplate();
      const params = template.parameters;
      const parse = (key: string, fallback: number) => {
        const defaultValue = params[key]?.defaultValue;
        const raw =
          defaultValue && "value" in defaultValue ? defaultValue.value : undefined;
        const parsed = raw ? Number(raw) : NaN;
        return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
      };
      singleLimit = parse("fraud_amount_single", singleLimit);
      dailyLimit = parse("fraud_amount_24h", dailyLimit);
    } catch (e) {
      logger.warn("Falling back to default limits", { error: String(e) });
    }

    const now = Timestamp.now();
    const dayAgo = new Timestamp(now.seconds - 86400, 0);
    const sentSnapshot = await db
      .collection("transfers")
      .where("fromWalletId", "==", uid)
      .where("status", "==", "completed")
      .where("createdAt", ">=", dayAgo)
      .get();

    let sentTodayMinor = 0;
    sentSnapshot.forEach((doc) => {
      const amount = doc.data()["amount"];
      if (typeof amount === "number") {
        sentTodayMinor += amount;
      }
    });

    return {
      singleLimitMinor: singleLimit,
      dailyLimitMinor: dailyLimit,
      sentTodayMinor,
      remainingTodayMinor: Math.max(0, dailyLimit - sentTodayMinor),
    };
  },
);
