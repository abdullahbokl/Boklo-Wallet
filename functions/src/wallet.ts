import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { FieldValue } from "@google-cloud/firestore";
import * as functions from "firebase-functions";
import { syncWalletPublic } from "./utils/wallet_public";

const db = admin.firestore();

/**
 * Provision a wallet for the authenticated user.
 * This is idempotent - if wallet exists, returns success immediately.
 * 
 * Use case: Fallback when onUserCreated trigger doesn't fire (e.g., hybrid dev setup)
 * or for any race condition where wallet is needed before trigger completes.
 */
export const provisionWallet = onCall(
  { region: "us-central1" },
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated to provision wallet."
      );
    }

    const uid = request.auth.uid;
    const email = request.auth.token?.email || "";
    const displayName = (request.auth.token as any)?.name || "";

    console.log("wallet.provision.start", { uid, email });

    const walletRef = db.collection("wallets").doc(uid);
    const userRef = db.collection("users").doc(uid);

    try {
      const walletSnapshot = await walletRef.get();

      if (walletSnapshot.exists) {
        console.log("wallet.provision.exists", { uid });
        return { 
          success: true, 
          created: false, 
          message: "Wallet already exists" 
        };
      }

      // Create wallet document
      await walletRef.set({
        id: uid,
        balance: 0, // integer minor units (EGP piastres)
        minorUnits: true,
        currency: "EGP",
        ownerId: uid,
        ownerEmail: email,
        ownerName: displayName,
        version: 0, // Optimistic concurrency control
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        isActive: true,
      });

      // Publish the public, balance-free profile for discovery/transfer flows.
      await syncWalletPublic(uid, {
        ownerName: displayName,
        username: null,
        alias: null,
        currency: "EGP",
        isActive: true,
      });

      console.log("wallet.provision.created", { uid });

      // Also ensure user profile exists
      await userRef.set({
        id: uid,
        email: email,
        displayName: displayName,
        username: null,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });

      return { 
        success: true, 
        created: true, 
        message: "Wallet created successfully" 
      };

    } catch (error: any) {
      console.error("wallet.provision.failed", { 
        uid, 
        errorCode: error.code, 
        message: error.message 
      });
      throw new functions.https.HttpsError(
        "internal",
        "Failed to provision wallet. Please try again."
      );
    }
  }
);
