import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

/**
 * Triggered when a new user is created in Firebase Auth.
 * Creates a corresponding Wallet document in Firestore.
 */
export const onUserCreated = functions.auth.user().onCreate(async (user) => {
    if (!user) {
        console.error("No user data in event");
        return;
    }

    const uid = user.uid;
    const email = user.email || "";
    const displayName = user.displayName || "";

    const db = admin.firestore();
    const walletRef = db.collection("wallets").doc(uid);

    try {
        const walletSnapshot = await walletRef.get();
        if (walletSnapshot.exists) {
            console.log(`Wallet for user ${uid} already exists.`);
            return;
        }

        // Create the wallet document
        await walletRef.set({
            id: uid,
            balance: 0,
            currency: "EGP", // Default currency
            ownerId: uid,
            ownerEmail: email,
            ownerName: displayName,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            isActive: true,
        });

        console.log(`Wallet created for user ${uid}`);

        // Also ensure the user document exists in 'users' collection with basic info
        // (Though client might have created it, good to be safe)
        const userRef = db.collection("users").doc(uid);
        await userRef.set({
            id: uid,
            email: email,
            displayName: displayName,
            username: null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});

        // Create O(1) identifier mapping for email (if present)
        if (email) {
            const emailLower = email.toLowerCase();
            await db.collection("wallet_identifiers").doc(`email:${emailLower}`).set({
                walletId: uid,
                uid: uid,
                type: 'email',
                value: emailLower,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
            console.log(`Email identifier mapping created for ${uid}`);
        }

    } catch (error) {
        console.error(`Error creating wallet for user ${uid}:`, error);
        throw error;
    }
});
