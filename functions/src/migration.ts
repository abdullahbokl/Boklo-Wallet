import * as admin from "firebase-admin";
import { FieldValue } from "@google-cloud/firestore";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";

/**
 * One-time migration function to backfill wallet_identifiers for existing users.
 * This creates O(1) lookup mappings for emails and usernames.
 * 
 * Call this once after deploying the new identifier resolution system.
 * Safe to run multiple times (idempotent).
 */
export const migrateWalletIdentifiers = onCall(
  { region: "us-central1" },
  async (request) => {
    // Admin-only: this job scans all users and writes identifier mappings.
    // Callers must carry the `admin` custom claim
    // (set via: admin.auth().setCustomUserClaims(uid, { admin: true })).
    if (!request.auth || request.auth.token.admin !== true) {
      throw new HttpsError(
        "permission-denied",
        "Only admins can run this migration",
      );
    }

    const db = admin.firestore();
    const startTime = Date.now();
    
    let emailCount = 0;
    let usernameCount = 0;
    let errorCount = 0;

    logger.info("Migration started", { event: "MIGRATION_START" });

    // 1. Migrate usernames from usernames collection
    const usernamesSnapshot = await db.collection("usernames").get();
    
    for (const doc of usernamesSnapshot.docs) {
      try {
        const username = doc.id; // Document ID is the lowercase username
        const uid = doc.data().uid;
        
        if (!uid) continue;

        await db.collection("wallet_identifiers").doc(`username:${username}`).set({
          walletId: uid,
          uid: uid,
          type: "username",
          value: username,
          createdAt: FieldValue.serverTimestamp(),
          migratedAt: FieldValue.serverTimestamp()
        }, { merge: true });
        
        usernameCount++;
      } catch (e) {
        errorCount++;
        logger.error("Username migration error", { username: doc.id, error: (e as Error).message });
      }
    }

    // 2. Migrate emails from users collection
    const usersSnapshot = await db.collection("users").get();
    
    for (const doc of usersSnapshot.docs) {
      try {
        const userData = doc.data();
        const uid = doc.id;
        const email = userData.email as string | undefined;
        
        if (!email) continue;

        const emailLower = email.toLowerCase();
        
        await db.collection("wallet_identifiers").doc(`email:${emailLower}`).set({
          walletId: uid,
          uid: uid,
          type: "email",
          value: emailLower,
          createdAt: FieldValue.serverTimestamp(),
          migratedAt: FieldValue.serverTimestamp()
        }, { merge: true });
        
        emailCount++;
      } catch (e) {
        errorCount++;
        logger.error("Email migration error", { uid: doc.id, error: (e as Error).message });
      }
    }

    const durationMs = Date.now() - startTime;
    
    logger.info("Migration completed", {
      event: "MIGRATION_COMPLETE",
      usernameCount,
      emailCount,
      errorCount,
      durationMs
    });

    return {
      success: true,
      usernamesMigrated: usernameCount,
      emailsMigrated: emailCount,
      errors: errorCount,
      durationMs
    };
  }
);
