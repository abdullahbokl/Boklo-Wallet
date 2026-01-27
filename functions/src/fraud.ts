
import * as admin from 'firebase-admin';
import * as logger from 'firebase-functions/logger';

export interface RiskAssessment {
    riskLevel: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
    action: 'ALLOW' | 'FLAG' | 'BLOCK';
    reasons: string[];
    evidence: Record<string, any>;
}

export interface FraudCheckContext {
    fromWalletId: string;
    amount: number;
    currency: string;
    userId?: string; // If available, for user-level velocity
}

// Configurable Risk Mode
export const RISK_MODE: 'ENFORCE' | 'MONITOR' = process.env.RISK_MODE === 'MONITOR' ? 'MONITOR' : 'ENFORCE';

// Hardcoded limits for MVP - move to Remote Config later
const LIMITS = {
    VELOCITY_1H: 5,       // Max 5 transfers per hour
    VELOCITY_24H: 20,     // Max 20 transfers per 24 hours
    AMOUNT_SINGLE: 5000,  // Max amount per single transfer
    AMOUNT_24H: 10000,    // Max cumulative amount per 24 hours (optional, maybe Phase 2.1)
    FAILURE_RATE_1H: 3    // Max 3 failed attempts per hour
};


/**
 * Evaluates the risk of a transfer request.
 * 
 * @param db Firestore database instance
 * @param context context for the fraud check
 * @returns RiskAssessment object
 */
export async function evaluateRisk(
    db: admin.firestore.Firestore,
    context: FraudCheckContext
): Promise<RiskAssessment> {
    const { fromWalletId, amount } = context;
    const reasons: string[] = [];
    const evidence: Record<string, any> = {};
    let riskScore = 0;

    // 1. Amount Check
    if (amount > LIMITS.AMOUNT_SINGLE) {
        reasons.push(`Amount ${amount} exceeds single transfer limit of ${LIMITS.AMOUNT_SINGLE}`);
        riskScore += 50; // High impact
        evidence.amountExceeded = true;
    }

    // 2. Velocity Checks (Firestore Queries)
    // We need to count recent transfers. 
    // Ideally, this should use a counter or a dedicated aggregation, 
    // but for "Fraud-lite" we'll do a count query with a limit.
    
    const now = admin.firestore.Timestamp.now();
    const oneHourAgo = new admin.firestore.Timestamp(now.seconds - 3600, 0);
    const twentyFourHoursAgo = new admin.firestore.Timestamp(now.seconds - 86400, 0);

    // Run queries in parallel
    const [transfersLastHour, transfersLast24h] = await Promise.all([
        getTransferCount(db, fromWalletId, oneHourAgo),
        getTransferCount(db, fromWalletId, twentyFourHoursAgo)
    ]);

    evidence.velocity1h = transfersLastHour;
    evidence.velocity24h = transfersLast24h;

    if (transfersLastHour >= LIMITS.VELOCITY_1H) {
        reasons.push(`Velocity (1h) exceeded: ${transfersLastHour}/${LIMITS.VELOCITY_1H}`);
        riskScore += 30;
    }

    if (transfersLast24h >= LIMITS.VELOCITY_24H) {
        reasons.push(`Velocity (24h) exceeded: ${transfersLast24h}/${LIMITS.VELOCITY_24H}`);
        riskScore += 20;
    }

    // 3. Failure Rate Check
    // High number of failures might indicate guessing or system abuse
    const failedTransfersLastHour = await getFailedTransferCount(db, fromWalletId, oneHourAgo);
    evidence.failedTransfers1h = failedTransfersLastHour;

    if (failedTransfersLastHour >= LIMITS.FAILURE_RATE_1H) {
        reasons.push(`Failure rate (1h) exceeded: ${failedTransfersLastHour}/${LIMITS.FAILURE_RATE_1H}`);
        riskScore += 40; // Significant risk
    }

    // 4. Determine Risk Level & Action
    let riskLevel: RiskAssessment['riskLevel'] = 'LOW';
    let action: RiskAssessment['action'] = 'ALLOW';

    if (riskScore >= 50) {
        riskLevel = 'HIGH';
        action = 'BLOCK'; // Default to BLOCK for high risk in MVP
    } else if (riskScore >= 20) {
        riskLevel = 'MEDIUM';
        action = 'FLAG';
    }

    // Log the evaluation
    logger.info("Risk evaluation completed", {
        event: "RISK_EVALUATION",
        fromWalletId,
        amount,
        riskScore,
        riskLevel,
        action,
        reasons
    });

    return {
        riskLevel,
        action,
        reasons,
        evidence
    };
}


/**
 * Creates a review item in the 'risk_reviews' collection.
 */
export async function createRiskReview(
    db: admin.firestore.Firestore,
    transferId: string,
    riskAssessment: RiskAssessment
): Promise<void> {
    try {
        await db.collection('risk_reviews').doc(transferId).set({
            transferId,
            status: 'PENDING', // PENDING, RESOLVED, IGNORED
            riskLevel: riskAssessment.riskLevel,
            reasons: riskAssessment.reasons,
            evidence: riskAssessment.evidence,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
    } catch (error) {
        logger.error("Failed to create risk review", {
            event: "RISK_REVIEW_CREATION_FAILED",
            transactionId: transferId,
            error: error instanceof Error ? error.message : 'Unknown error'
        });
    }
}

async function getTransferCount(
    db: admin.firestore.Firestore, 
    walletId: string, 
    since: admin.firestore.Timestamp
): Promise<number> {
    const snapshot = await db.collection('transfers')
        .where('fromWalletId', '==', walletId)
        .where('createdAt', '>=', since)
        .count()
        .get();
        
    return snapshot.data().count;
}

async function getFailedTransferCount(
    db: admin.firestore.Firestore,
    walletId: string,
    since: admin.firestore.Timestamp
): Promise<number> {
    const snapshot = await db.collection('transfers')
        .where('fromWalletId', '==', walletId)
        .where('status', '==', 'FAILED')
        .where('createdAt', '>=', since)
        .count()
        .get();
        
    return snapshot.data().count;
}
