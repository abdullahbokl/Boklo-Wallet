import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { FieldValue } from "@google-cloud/firestore";
import * as functions from "firebase-functions";

const db = admin.firestore();

interface SetUserProfileData {
  username: string;
  name?: string;
}

const accountDeletionCollections = {
  userSubcollections: ["tokens", "contacts", "preferences"],
  walletSubcollections: ["transactions", "ledger"],
} as const;

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
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
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
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
            isActive: true,
        });
    }
    
    // Case A: Username not changing, just name update
    if (currentUsername === usernameLower) {
        t.set(userRef, { 
            name: name || userData?.name || "",
            updatedAt: FieldValue.serverTimestamp() 
        }, { merge: true });
        
        if (name) {
             t.set(walletRef, { ownerName: name }, { merge: true });
        }
        return { success: true, username: usernameLower };
    }

    // Case B: New user or username change
    
    // Release old username if existed
    if (currentUsername && oldUsernameDoc?.exists && oldUsernameDoc.data()?.uid === uid) {
        const oldUsernameRef = db.collection("usernames").doc(currentUsername);
        t.delete(oldUsernameRef);
        // Also delete old identifier mapping
        t.delete(db.collection("wallet_identifiers").doc(`username:${currentUsername}`));
    }

    // Claim new username
    t.set(usernameRef, {
        uid: uid,
        username: usernameLower,
        createdAt: FieldValue.serverTimestamp()
    });

    // Create O(1) identifier mapping for username
    t.set(db.collection("wallet_identifiers").doc(`username:${usernameLower}`), {
        walletId: uid,
        uid: uid,
        type: 'username',
        value: usernameLower,
        createdAt: FieldValue.serverTimestamp()
    });

    // Update or Create User Profile (use set with merge to handle both cases)
    t.set(userRef, {
        ...(!userExisted ? userData : {}), // Spread base userData only if new
        username: usernameLower,
        name: name || userData?.name || "",
        updatedAt: FieldValue.serverTimestamp()
    }, { merge: true });

    // Update Wallet with username and ownerName
    t.set(walletRef, { 
        username: usernameLower,
        ...(name ? { ownerName: name } : {}),
        updatedAt: FieldValue.serverTimestamp()
    }, { merge: true });

    return { success: true, username: usernameLower };
  });
});

export const deleteAccount = onCall(
  { region: "us-central1" },
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
      );
    }

    const uid = request.auth.uid;
    const walletRef = db.collection("wallets").doc(uid);
    const userRef = db.collection("users").doc(uid);

    const [walletDoc, userDoc] = await Promise.all([
      walletRef.get(),
      userRef.get(),
    ]);

    const balance = Number(walletDoc.data()?.balance ?? 0);
    if (balance != 0) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "You can only delete your account when your wallet balance is zero."
      );
    }

    const hasTransferHistory = await _queryExists([
      db.collection("transfers")
        .where("fromWalletId", "==", uid)
        .limit(1),
      db.collection("transfers")
        .where("toWalletId", "==", uid)
        .limit(1),
    ]);

    if (hasTransferHistory) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Your account cannot be deleted because transfer history exists."
      );
    }

    const hasPaymentRequestHistory = await _queryExists([
      db.collection("payment_requests")
        .where("requesterId", "==", uid)
        .limit(1),
      db.collection("payment_requests")
        .where("payerId", "==", uid)
        .limit(1),
    ]);

    if (hasPaymentRequestHistory) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Your account cannot be deleted because payment request history exists."
      );
    }

    const email = (
      (userDoc.data()?.email as string | undefined) ??
      (request.auth.token.email as string | undefined) ??
      ""
    )
      .toLowerCase();
    const username = (
      (userDoc.data()?.username as string | undefined) ??
      ""
    ).toLowerCase();

    try {
      await Promise.all([
        _deleteSubcollections(userRef, accountDeletionCollections.userSubcollections),
        _deleteSubcollections(walletRef, accountDeletionCollections.walletSubcollections),
        _deleteNotificationsForUser(uid),
      ]);

      const cleanupWrites: Array<Promise<unknown>> = [
        userRef.delete().catch((error: unknown) => _ignoreMissingDoc(error)),
        walletRef.delete().catch((error: unknown) => _ignoreMissingDoc(error)),
      ];

      if (email !== "") {
        cleanupWrites.push(
          db.collection("wallet_identifiers")
            .doc(`email:${email}`)
            .delete()
            .catch((error: unknown) => _ignoreMissingDoc(error))
        );
      }

      if (username !== "") {
        cleanupWrites.push(
          db.collection("usernames")
            .doc(username)
            .delete()
            .catch((error: unknown) => _ignoreMissingDoc(error))
        );
        cleanupWrites.push(
          db.collection("wallet_identifiers")
            .doc(`username:${username}`)
            .delete()
            .catch((error: unknown) => _ignoreMissingDoc(error))
        );
      }

      await Promise.all(cleanupWrites);
      await admin.auth().deleteUser(uid);

      return { success: true };
    } catch (error) {
      console.error("deleteAccount failed", {
        uid,
        error: error instanceof Error ? error.message : String(error),
      });
      throw new functions.https.HttpsError(
        "internal",
        "Failed to delete account. Please try again."
      );
    }
  }
);

async function _queryExists(
  queries: Array<FirebaseFirestore.Query<FirebaseFirestore.DocumentData>>
) {
  const snapshots = await Promise.all(queries.map((query) => query.get()));
  return snapshots.some((snapshot) => !snapshot.empty);
}

async function _deleteSubcollections(
  docRef: admin.firestore.DocumentReference,
  subcollections: readonly string[]
) {
  await Promise.all(
    subcollections.map(async (subcollection) => {
      const snapshot = await docRef.collection(subcollection).get();
      await _deleteDocs(snapshot.docs.map((doc) => doc.ref));
    })
  );
}

async function _deleteNotificationsForUser(uid: string) {
  const snapshot = await db.collection("notifications")
    .where("userId", "==", uid)
    .get();
  await _deleteDocs(snapshot.docs.map((doc) => doc.ref));
}

async function _deleteDocs(refs: admin.firestore.DocumentReference[]) {
  if (refs.length === 0) {
    return;
  }

  const chunkSize = 400;
  for (let index = 0; index < refs.length; index += chunkSize) {
    const batch = db.batch();
    for (const ref of refs.slice(index, index + chunkSize)) {
      batch.delete(ref);
    }
    await batch.commit();
  }
}

function _ignoreMissingDoc(error: unknown) {
  const code = (error as { code?: number | string }).code;
  if (code === 5 || code === "not-found") {
    return;
  }
  throw error;
}
