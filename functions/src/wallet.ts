import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

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
        balance: 0,
        currency: "EGP",
        ownerId: uid,
        ownerEmail: email,
        ownerName: displayName,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
      });

      console.log("wallet.provision.created", { uid });

      // Also ensure user profile exists
      await userRef.set({
        id: uid,
        email: email,
        displayName: displayName,
        username: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
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
