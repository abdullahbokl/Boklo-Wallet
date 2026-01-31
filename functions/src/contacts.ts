import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {logger} from "firebase-functions";
import {onCall} from "firebase-functions/v2/https";

const db = admin.firestore();

/**
 * Adds a contact by email or username.
 * Lookups the user and if found, adds them to the requesting user's contacts.
 */
export const addContact = onCall(async (request) => {
    if (!request.auth) {
        throw new functions.https.HttpsError("unauthenticated", "The function must be called while authenticated.");
    }

    const { email, username } = request.data as { email?: string; username?: string };
    
    if (!email && !username) {
        throw new functions.https.HttpsError("invalid-argument", "Must provide either email or username.");
    }

    const requesterId = request.auth.uid;
    let contactUid: string;
    let contactEmail: string;
    let displayName: string;
    let photoUrl: string | null = null;

    try {
        if (email) {
            // Lookup by email using Firebase Auth
            const userRecord = await admin.auth().getUserByEmail(email);
            contactUid = userRecord.uid;
            contactEmail = userRecord.email || email;
            displayName = userRecord.displayName || email.split('@')[0];
            photoUrl = userRecord.photoURL || null;
        } else {
            // O(1) Lookup by username using wallet_identifiers mapping
            const startTime = Date.now();
            const usernameLower = username!.toLowerCase().replace(/^@/, ''); // Remove @ if present
            
            logger.info("Identifier resolution started", {
                event: "IDENTIFIER_RESOLUTION",
                inputType: 'username',
                inputValue: usernameLower.substring(0, 3) + '***' // Masked for privacy
            });

            const mappingDoc = await db.collection("wallet_identifiers").doc(`username:${usernameLower}`).get();
            
            if (!mappingDoc.exists) {
                logger.warn("Identifier resolution failed", {
                    event: "IDENTIFIER_RESOLUTION",
                    error: "IDENTIFIER_NOT_REGISTERED",
                    durationMs: Date.now() - startTime
                });
                throw new functions.https.HttpsError("not-found", "User with this username does not exist.");
            }

            const mappingData = mappingDoc.data()!;
            contactUid = mappingData.walletId as string;

            logger.info("Identifier resolution completed", {
                event: "IDENTIFIER_RESOLUTION",
                durationMs: Date.now() - startTime,
                success: true
            });

            // Fetch user profile for display name and email
            const userDoc = await db.collection("users").doc(contactUid).get();
            if (!userDoc.exists) {
                throw new functions.https.HttpsError("not-found", "User profile not found.");
            }

            const userData = userDoc.data()!;
            contactEmail = userData.email || "";
            displayName = userData.displayName || userData.name || usernameLower;
            photoUrl = userData.photoUrl || null;
        }

        if (contactUid === requesterId) {
            throw new functions.https.HttpsError("invalid-argument", "You cannot add yourself as a contact.");
        }

        const contactData = {
            uid: contactUid,
            displayName: displayName,
            photoUrl: photoUrl,
            email: contactEmail,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        // Add to contacts subcollection
        await db
            .collection("users")
            .doc(requesterId)
            .collection("contacts")
            .doc(contactUid)
            .set(contactData);

        logger.info("Contact added", { requesterId, contactUid });
        return { success: true, contact: contactData };

    } catch (error: any) {
        logger.error("Error adding contact", error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        if (error.code === 'auth/user-not-found') {
            throw new functions.https.HttpsError("not-found", "User with this email does not exist.");
        }
        throw new functions.https.HttpsError("internal", "Unable to add contact.");
    }
});

