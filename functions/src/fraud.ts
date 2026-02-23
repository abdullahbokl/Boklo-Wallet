
import * as admin from 'firebase-admin';
import { FieldValue, Timestamp } from "@google-cloud/firestore";
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

// Default limits — used as fallback when Remote Config is unavailable
const DEFAULT_LIMITS = {
    VELOCITY_1H: 5,
    VELOCITY_24H: 20,
    AMOUNT_SINGLE: 5000,
    AMOUNT_24H: 10000,
    FAILURE_RATE_1H: 3,
};

interface FraudLimits {
    VELOCITY_1H: number;
    VELOCITY_24H: number;
    AMOUNT_SINGLE: number;
    AMOUNT_24H: number;
    FAILURE_RATE_1H: number;
}

// Cache for Remote Config limits (5-minute TTL)
let _cachedLimits: FraudLimits | null = null;
let _cacheTimestamp = 0;
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

/**
 * Fetches fraud limits from Remote Config with caching.
 * Falls back gracefully to DEFAULT_LIMITS on any failure.
 */
async function getFraudLimits(): Promise<FraudLimits> {
    const now = Date.now();
    if (_cachedLimits && (now - _cacheTimestamp) < CACHE_TTL_MS) {
        return _cachedLimits;
    }

    try {
        const rc = admin.remoteConfig();
        const template = await rc.getTemplate();
        const params = template.parameters;

        _cachedLimits = {
            VELOCITY_1H: getNumericParam(params, 'fraud_velocity_1h', DEFAULT_LIMITS.VELOCITY_1H),
            VELOCITY_24H: getNumericParam(params, 'fraud_velocity_24h', DEFAULT_LIMITS.VELOCITY_24H),
            AMOUNT_SINGLE: getNumericParam(params, 'fraud_amount_single', DEFAULT_LIMITS.AMOUNT_SINGLE),
            AMOUNT_24H: getNumericParam(params, 'fraud_amount_24h', DEFAULT_LIMITS.AMOUNT_24H),
            FAILURE_RATE_1H: getNumericParam(params, 'fraud_failure_rate_1h', DEFAULT_LIMITS.FAILURE_RATE_1H),
        };
        _cacheTimestamp = now;

        logger.info("Fraud limits loaded from Remote Config", {
            event: "FRAUD_LIMITS_LOADED",
            limits: _cachedLimits,
        });

        return _cachedLimits;
    } catch (error) {
        logger.warn("Failed to load Remote Config fraud limits, using defaults", {
            event: "FRAUD_LIMITS_FALLBACK",
            error: error instanceof Error ? error.message : 'Unknown error',
        });
        return DEFAULT_LIMITS;
    }
}

function getNumericParam(
    params: Record<string, any>,
    key: string,
    fallback: number,
): number {
    const param = params[key];
    if (param?.defaultValue?.value) {
        const parsed = Number(param.defaultValue.value);
        return isNaN(parsed) ? fallback : parsed;
    }
    return fallback;
}


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

    // Fetch limits from Remote Config (cached, with fallback)
    const limits = await getFraudLimits();
    evidence.limitsUsed = limits;

    // 1. Amount Check
    if (amount > limits.AMOUNT_SINGLE) {
        reasons.push(`Amount ${amount} exceeds single transfer limit of ${limits.AMOUNT_SINGLE}`);
        riskScore += 50;
        evidence.amountExceeded = true;
    }

    // 2. Velocity Checks (Firestore Queries)
    const now = Timestamp.now();
    const oneHourAgo = new Timestamp(now.seconds - 3600, 0);
    const twentyFourHoursAgo = new Timestamp(now.seconds - 86400, 0);

    const [transfersLastHour, transfersLast24h] = await Promise.all([
        getTransferCount(db, fromWalletId, oneHourAgo),
        getTransferCount(db, fromWalletId, twentyFourHoursAgo)
    ]);

    evidence.velocity1h = transfersLastHour;
    evidence.velocity24h = transfersLast24h;

    if (transfersLastHour >= limits.VELOCITY_1H) {
        reasons.push(`Velocity (1h) exceeded: ${transfersLastHour}/${limits.VELOCITY_1H}`);
        riskScore += 30;
    }

    if (transfersLast24h >= limits.VELOCITY_24H) {
        reasons.push(`Velocity (24h) exceeded: ${transfersLast24h}/${limits.VELOCITY_24H}`);
        riskScore += 20;
    }

    // 3. Failure Rate Check
    const failedTransfersLastHour = await getFailedTransferCount(db, fromWalletId, oneHourAgo);
    evidence.failedTransfers1h = failedTransfersLastHour;

    if (failedTransfersLastHour >= limits.FAILURE_RATE_1H) {
        reasons.push(`Failure rate (1h) exceeded: ${failedTransfersLastHour}/${limits.FAILURE_RATE_1H}`);
        riskScore += 40;
    }

    // 4. Determine Risk Level & Action
    let riskLevel: RiskAssessment['riskLevel'] = 'LOW';
    let action: RiskAssessment['action'] = 'ALLOW';

    if (riskScore >= 50) {
        riskLevel = 'HIGH';
        action = 'BLOCK';
    } else if (riskScore >= 20) {
        riskLevel = 'MEDIUM';
        action = 'FLAG';
    }

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
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp()
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
    since: Timestamp
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
    since: Timestamp
): Promise<number> {
    const snapshot = await db.collection('transfers')
        .where('fromWalletId', '==', walletId)
        .where('status', '==', 'FAILED')
        .where('createdAt', '>=', since)
        .count()
        .get();
        
    return snapshot.data().count;
}
