import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

/**
 * FX foundations: currency conversion primitives.
 *
 * POLICY: transfers remain strictly same-currency (see
 * currenciesAreCompatible in utils/money). Conversion is NOT applied to
 * any live money movement yet. These primitives exist so multi-currency
 * support can be layered on later without redesigning the money model.
 *
 * Representations:
 *  - Amounts are integer minor units, as everywhere else in the ledger.
 *  - Rates are stored as an exact rational (rateNum / rateDen), never a
 *    float, so conversion is reproducible and auditable:
 *    result = amountMinor * rateNum / rateDen, rounded half-up.
 */

export interface FxRate {
    /** Quote currency code, e.g. "USD". */
    readonly quote: string;
    /** Base currency code, e.g. "EGP". */
    readonly base: string;
    /** Exact rate numerator: 1 base = rateNum/rateDen quote minor units. */
    readonly rateNum: number;
    /** Exact rate denominator (> 0). */
    readonly rateDen: number;
    /** ISO timestamp of the rate source snapshot. */
    readonly asOf: string;
}

/** Firestore doc id for a pair, e.g. fx_rates/EGP_USD. */
export function fxRateDocId(base: string, quote: string): string {
    return `${base.toUpperCase()}_${quote.toUpperCase()}`;
}

/**
 * Converts an amount between currencies using an exact rational rate.
 * Integer-only math: no float ever touches a monetary value.
 */
export function convertMinorWithRate(
    amountMinor: number,
    rateNum: number,
    rateDen: number,
): number {
    if (!Number.isInteger(amountMinor) || amountMinor < 0) {
        throw new Error("amountMinor must be a non-negative integer");
    }
    if (!Number.isInteger(rateNum) || !Number.isInteger(rateDen) || rateDen <= 0) {
        throw new Error("rate must be an exact rational with rateDen > 0");
    }
    // Half-up rounding of amountMinor * rateNum / rateDen.
    const numerator = amountMinor * rateNum;
    const quotient = Math.floor(numerator / rateDen);
    const remainder = numerator - quotient * rateDen;
    return remainder * 2 >= rateDen ? quotient + 1 : quotient;
}

/** Reads a stored rate; null when the pair has never been published. */
export async function getFxRate(
    base: string,
    quote: string,
): Promise<FxRate | null> {
    const doc = await db.collection("fx_rates").doc(fxRateDocId(base, quote)).get();
    if (!doc.exists) return null;
    const data = doc.data()!;
    return {
        base: data.base as string,
        quote: data.quote as string,
        rateNum: data.rateNum as number,
        rateDen: data.rateDen as number,
        asOf: data.asOf as string,
    };
}

/**
 * Callable-shaped helper (exposed via an onCall in index wiring): returns
 * a quote for the caller. Rates are public data; the callable exists so
 * App Check / auth semantics stay uniform with the rest of the API.
 */
export async function quoteConversion(
    amountMinor: number,
    base: string,
    quote: string,
): Promise<{ amountMinor: number; convertedMinor: number; rate: FxRate } | null> {
    const rate = await getFxRate(base, quote);
    if (rate == null) {
        logger.warn(`No FX rate stored for ${base}->${quote}`);
        return null;
    }
    return {
        amountMinor,
        convertedMinor: convertMinorWithRate(amountMinor, rate.rateNum, rate.rateDen),
        rate,
    };
}


/**
 * Callable: converts an amount between currencies using the stored exact
 * rational rate. Advisory only — no ledger movement is performed.
 */
export const getFxQuote = onCall({ region: "us-central1" }, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Sign in first.");
    }
    const amountMinor = Number(request.data?.amountMinor);
    const base = String(request.data?.base ?? "").toUpperCase();
    const quote = String(request.data?.quote ?? "").toUpperCase();

    if (!Number.isInteger(amountMinor) || amountMinor < 0) {
        throw new HttpsError(
            "invalid-argument",
            "amountMinor must be a non-negative integer.",
        );
    }
    if (!base || !quote) {
        throw new HttpsError(
            "invalid-argument",
            "base and quote currency codes are required.",
        );
    }

    const result = await quoteConversion(amountMinor, base, quote);
    if (result == null) {
        throw new HttpsError(
            "failed-precondition",
            "No rate available for this currency pair.",
        );
    }
    return result;
});
