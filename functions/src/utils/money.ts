import * as logger from "firebase-functions/logger";

/**
 * Money representation
 * ====================
 * All monetary values in Firestore (wallet balances, transfer amounts,
 * transaction and ledger amounts, payment request amounts) are stored as
 * INTEGER MINOR UNITS (e.g. piastres for EGP: 100 = EGP 1.00).
 *
 * Every document that carries money carries the `minorUnits: true` marker.
 * Documents written before the migration (and by any legacy writer) lack
 * the marker; the `migrateMoneyToMinorUnits` admin callable converts them.
 * The transfer execution transaction FAILS CLOSED on unmigrated wallets
 * rather than misinterpreting a major-unit value as minor units.
 */
export const MINOR_UNIT_FACTOR = 100;

/** Converts a major-unit value (e.g. 10.5) to integer minor units (1050). */
export function toMinorUnits(major: number): number {
  return Math.round(major * MINOR_UNIT_FACTOR);
}

/** Formats an integer minor-unit amount as a fixed-2 major-unit string. */
export function formatMajor(amountMinor: number): string {
  return (amountMinor / MINOR_UNIT_FACTOR).toFixed(2);
}

export function hasMinorUnitsFlag(data: Record<string, unknown> | undefined): boolean {
  return data?.["minorUnits"] === true;
}

/** Logs (once per value) when a document unexpectedly lacks the flag. */
export function warnMissingMinorUnits(collection: string, id: string): void {
  logger.warn("Document missing minorUnits flag", {
    event: "MINOR_UNITS_FLAG_MISSING",
    collection,
    docId: id,
  });
}

/**
 * Currency integrity rule: we never convert. The transfer currency, the
 * sender wallet currency, and the receiver wallet currency must all match.
 */
export function currenciesAreCompatible(
  transferCurrency: unknown,
  fromWalletCurrency: unknown,
  toWalletCurrency: unknown,
): boolean {
  return (
    typeof transferCurrency === "string" &&
    transferCurrency.length > 0 &&
    transferCurrency === fromWalletCurrency &&
    transferCurrency === toWalletCurrency
  );
}
