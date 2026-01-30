import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

const db = admin.firestore();

interface SetUserProfileData {
  username: string;
  name?: string;
}

// Explicit region for consistency between emulator and production
export const setUserProfile = onCall<SetUserProfileData>(
  { region: "us-central1" },
  async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const uid = request.auth.uid;
  const { username, name } = request.data;

  // 1. Validation
  if (!username) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Username is required."
    );
  }

  if (username.length < 3 || username.length > 20) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Username must be between 3 and 20 characters."
    );
  }

  // Allowed chars: a-z 0-9 _ .
  const usernameRegex = /^[a-zA-Z0-9_.]+$/;
  if (!usernameRegex.test(username)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Username contains invalid characters."
    );
  }

  const usernameLower = username.toLowerCase();
  
  // Reserved words
  const reserved = ["admin", "support", "boklo", "wallet", "null", "undefined", "system", "superuser", "root"];
  if (reserved.includes(usernameLower)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "This username is reserved."
    );
  }
  
  // Name validation
  if (name && name.length > 50) {
      throw new functions.https.HttpsError(
      "invalid-argument",
      "Name must be less than 50 characters."
    );
  }

  return db.runTransaction(async (t) => {
    const userRef = db.collection("users").doc(uid);
    const usernameRef = db.collection("usernames").doc(usernameLower);
    const walletRef = db.collection("wallets").doc(uid);

    // 1. PERFORM ALL READS FIRST
    const userDoc = await t.get(userRef);
    const usernameDoc = await t.get(usernameRef);
    const walletDoc = await t.get(walletRef);
    
    let userData = userDoc.data();
    const currentUsername = userData?.username;
    const userExisted = userDoc.exists;
    const walletExisted = walletDoc.exists;
    
    let oldUsernameDoc = null;
    if (currentUsername && currentUsername !== usernameLower) {
        const oldUsernameRef = db.collection("usernames").doc(currentUsername);
        oldUsernameDoc = await t.get(oldUsernameRef);
    }

    // 2. LOGIC & VALIDATION (No writes yet)
    if (!userExisted) {
        console.log(`User profile for ${uid} missing. Will create.`);
        userData = {
            id: uid,
            email: request.auth?.token?.email || "",
            displayName: name || (request.auth?.token as any)?.name || "",
            username: null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
    }

    if (usernameDoc.exists && usernameDoc.data()?.uid !== uid) {
        throw new functions.https.HttpsError(
            "already-exists",
            "Username is already taken."
        );
    }

    // 3. PERFORM ALL WRITES
    
    // Ensure wallet exists (critical for hybrid dev setup where onUserCreated didn't fire)
    if (!walletExisted) {
        console.log(`Wallet for ${uid} missing. Creating.`);
        t.set(walletRef, {
            id: uid,
            balance: 0,
            currency: "EGP",
            ownerId: uid,
            ownerEmail: request.auth?.token?.email || "",
            ownerName: name || (request.auth?.token as any)?.name || "",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            isActive: true,
        });
    }
    
    // Case A: Username not changing, just name update
    if (currentUsername === usernameLower) {
        t.set(userRef, { 
            name: name || userData?.name || "",
            updatedAt: admin.firestore.FieldValue.serverTimestamp() 
        }, { merge: true });
        
        if (name) {
             t.set(walletRef, { ownerName: name }, { merge: true });
        }
        return { success: true };
    }

    // Case B: New user or username change
    
    // Release old username if existed
    if (currentUsername && oldUsernameDoc?.exists && oldUsernameDoc.data()?.uid === uid) {
        const oldUsernameRef = db.collection("usernames").doc(currentUsername);
        t.delete(oldUsernameRef);
    }

    // Claim new username
    t.set(usernameRef, {
        uid: uid,
        username: usernameLower,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Update or Create User Profile (use set with merge to handle both cases)
    t.set(userRef, {
        ...(!userExisted ? userData : {}), // Spread base userData only if new
        username: usernameLower,
        name: name || userData?.name || "",
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    // Update Wallet ownerName if name provided
    if (name && walletExisted) {
         t.set(walletRef, { ownerName: name }, { merge: true });
    }

    return { success: true };
  });
});
