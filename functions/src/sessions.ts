import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

interface DeviceInfo {
    token: string;
    platform: string;
    createdAt: string | null;
}

/**
 * Callable: lists the caller's registered push-notification devices
 * (FCM token docs under users/{uid}/tokens). Authenticated caller only;
 * the rules already restrict token reads to the owner.
 */
export const listDevices = onCall({ region: "us-central1" }, async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new HttpsError(
            "unauthenticated",
            "Sign in to manage devices.",
        );
    }

    const snapshot = await db
        .collection("users")
        .doc(uid)
        .collection("tokens")
        .get();

    const devices: DeviceInfo[] = snapshot.docs.map((doc) => {
        const data = doc.data();
        const createdAt = data.createdAt as admin.firestore.Timestamp | undefined;
        return {
            token: doc.id,
            platform: (data.platform as string | undefined) ?? "unknown",
            createdAt: createdAt ? createdAt.toDate().toISOString() : null,
        };
    });

    return { devices };
});

/**
 * Callable: "sign out everywhere". Revokes all of the caller's refresh
 * tokens (forcing re-authentication on every device) and deletes all FCM
 * token docs so no device keeps receiving pushes until it signs in again.
 * The current session keeps its ID token until it expires, which is the
 * expected Firebase semantics; the client signs out locally right after.
 */
export const revokeAllSessions = onCall(
    { region: "us-central1" },
    async (request) => {
        const uid = request.auth?.uid;
        if (!uid) {
            throw new HttpsError(
                "unauthenticated",
                "Sign in to manage devices.",
            );
        }

        // Force re-auth on all devices.
        await admin.auth().revokeRefreshTokens(uid);

        // Remove push registrations.
        const tokens = await db
            .collection("users")
            .doc(uid)
            .collection("tokens")
            .get();

        const batch = db.batch();
        tokens.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();

        logger.info("Revoked all sessions", {
            uid,
            removedTokens: tokens.size,
        });
        return { revoked: true, removedTokens: tokens.size };
    },
);
