import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {logger} from "firebase-functions";
import {onCall} from "firebase-functions/v2/https";

/**
 * Adds a contact by email.
 * Lookups the user by email, and if found, adds them to the requesting user's contacts.
 */
export const addContact = onCall(async (request) => {
    if (!request.auth) {
        throw new functions.https.HttpsError("unauthenticated", "The function must be called while authenticated.");
    }

    const email = request.data.email;
    if (!email || typeof email !== 'string') {
        throw new functions.https.HttpsError("invalid-argument", "The function must be called with a valid email.");
    }

    const requesterId = request.auth.uid;

    try {
        const userRecord = await admin.auth().getUserByEmail(email);
        const contactUid = userRecord.uid;

        if (contactUid === requesterId) {
            throw new functions.https.HttpsError("invalid-argument", "You cannot add yourself as a contact.");
        }

        // Fetch user profile for display name?
        // Or just store what Auth provides? Auth userRecord has displayName and photoURL.
        const contactData = {
            uid: contactUid,
            displayName: userRecord.displayName || email.split('@')[0],
            photoUrl: userRecord.photoURL || null,
            email: userRecord.email, // Safe to store? Yes, user provided it.
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        // Add to contacts subcollection
        await admin.firestore()
            .collection("users")
            .doc(requesterId)
            .collection("contacts")
            .doc(contactUid)
            .set(contactData);

        return { success: true, contact: contactData };

    } catch (error: any) {
        logger.error("Error adding contact", error);
        if (error.code === 'auth/user-not-found') {
            throw new functions.https.HttpsError("not-found", "User with this email does not exist.");
        }
        throw new functions.https.HttpsError("internal", "Unable to add contact.");
    }
});
