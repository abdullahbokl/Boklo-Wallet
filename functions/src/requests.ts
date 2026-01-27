import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

// Ensure Firebase is initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}
const db = admin.firestore();

/**
 * Trigger: onPaymentRequestCreated
 * 
 * Validates the request and emits an event (which can be picked up by notifications).
 * 
 * Structure of `payment_requests` doc:
 * {
 *   requesterId: string,
 *   requesterWalletId: string,
 *   payerId: string, // User ID of the person being requested
 *   amount: number,
 *   currency: string,
 *   status: 'PENDING',
 *   createdAt: Timestamp,
 *   note?: string
 * }
 */
export const onPaymentRequestCreated = onDocumentCreated("payment_requests/{requestId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
        return;
    }
    const requestId = event.params.requestId;
    const data = snapshot.data();

    logger.info("Payment Request created", {
        event: "PAYMENT_REQUEST_CREATED",
        requestId,
        requester: data.requesterId,
        payer: data.payerId,
        amount: data.amount
    });

    // Validations
    if (data.amount <= 0) {
        logger.warn("Invalid amount in payment request", { requestId, amount: data.amount });
        await snapshot.ref.update({ status: 'INVALID', error: 'Amount must be greater than 0' });
        return;
    }

    if (data.requesterId === data.payerId) {
        logger.warn("Self-request attempted", { requestId });
        await snapshot.ref.update({ status: 'INVALID', error: 'Cannot request money from yourself' });
        return;
    }

    // TODO: Verify Payer Exists? 
    // For now, assuming client side checks + later notification failure handles it.

    // Emit Event for Notifications
    // We can write to `events` collection to unify notification logic.
    // EventType: PAYMENT_REQUEST_CREATED
    const eventId = `${requestId}_created`;
    try {
        await db.collection("events").doc(eventId).create({
            eventId: eventId,
            eventType: "PAYMENT_REQUEST_CREATED",
            occurredAt: admin.firestore.FieldValue.serverTimestamp(),
            requestId: requestId,
            requesterId: data.requesterId,
            payerId: data.payerId,
            amount: data.amount,
            currency: data.currency
        });
    } catch (e: any) {
        if (e.code !== 6) { // ALREADY EVENTS
             logger.error("Failed to emit payment request event", { error: e.message });
        }
    }
});

/**
 * Callable: acceptPaymentRequest
 * 
 * Payer accepts the request.
 * 1. Validates request status is PENDING.
 * 2. Checks Payer (caller) is the `payerId`.
 * 3. Creates a `transfers` document (Payer -> Requester).
 * 4. Updates request status to `ACCEPTED`.
 */
export const acceptPaymentRequest = onCall(async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new HttpsError('unauthenticated', 'User must be logged in');
    }

    const { requestId } = request.data;
    if (!requestId) {
        throw new HttpsError('invalid-argument', 'Missing requestId');
    }

    const requestRef = db.collection('payment_requests').doc(requestId);
    
    try {
        await db.runTransaction(async (t) => {
            const doc = await t.get(requestRef);
            if (!doc.exists) {
                throw new HttpsError('not-found', 'Payment request not found');
            }
            
            const data = doc.data()!;
            
            // 1. Validate Ownership
            if (data.payerId !== uid) {
                throw new HttpsError('permission-denied', 'You are not the payer of this request');
            }

            // 2. Validate Status
            if (data.status !== 'PENDING') {
                 throw new HttpsError('failed-precondition', `Request is already ${data.status}`);
            }

            // 3. Resolve Wallets
            // We need Payer's wallet ID.
            // Assuming 1:1 user-wallet for MVP or we look it up.
            // Let's assume we can fetch wallet via `wallets` collection query where userId == uid
            // OR the client passes `payerWalletId`? 
            // Better security: Look it up backend side.
            const walletQuery = await t.get(db.collection('wallets').where('userId', '==', uid).limit(1));
            if (walletQuery.empty) {
                throw new HttpsError('failed-precondition', 'Payer wallet not found');
            }
            const payerWalletId = walletQuery.docs[0].id;
            
            // 4. Create Transfer
            // Payer (Scanner/Accepter) sends money TO Requester.
            const transferRef = db.collection('transfers').doc();
            const transferData = {
                fromWalletId: payerWalletId,
                toWalletId: data.requesterWalletId,
                amount: data.amount,
                currency: data.currency,
                description: data.note || 'Payment Request Accepted',
                userId: uid, // The ACTOR (sender)
                status: 'pending',
                type: 'p2p',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                metadata: {
                    relatedRequestId: requestId
                }
            };
            
            t.set(transferRef, transferData);

            // 5. Update Request Status
            t.update(requestRef, {
                status: 'ACCEPTED',
                transferId: transferRef.id,
                acceptedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        return { success: true };

    } catch (e: any) {
        logger.error("acceptPaymentRequest failed", { requestId, error: e.message });
        if (e instanceof HttpsError) throw e;
        throw new HttpsError('internal', 'Internal error processing request');
    }
});

/**
 * Callable: declinePaymentRequest
 */
export const declinePaymentRequest = onCall(async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new HttpsError('unauthenticated', 'User must be logged in');
    }

    const { requestId } = request.data;
    if (!requestId) {
         throw new HttpsError('invalid-argument', 'Missing requestId');
    }

    const requestRef = db.collection('payment_requests').doc(requestId);

    try {
        await db.runTransaction(async (t) => {
            const doc = await t.get(requestRef);
            if (!doc.exists) {
                throw new HttpsError('not-found', 'Payment request not found');
            }
            
            const data = doc.data()!;

            if (data.payerId !== uid) {
                throw new HttpsError('permission-denied', 'You are not the payer of this request');
            }

            if (data.status !== 'PENDING') {
                throw new HttpsError('failed-precondition', `Request is already ${data.status}`);
            }

            t.update(requestRef, {
                status: 'DECLINED',
                declinedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        return { success: true };
    } catch (e: any) {
        logger.error("declinePaymentRequest failed", { requestId, error: e.message });
        if (e instanceof HttpsError) throw e;
        throw new HttpsError('internal', 'Internal error processing request');
    }
});
