import { randomUUID } from "crypto";

/**
 * Generates a unique correlation ID for end-to-end request tracing.
 * 
 * Correlation IDs flow: Transfer → Events → Ledger → Notifications → BigQuery
 * Every log entry within a request chain shares the same correlationId,
 * enabling grep-based debugging across Cloud Functions.
 * 
 * Usage:
 *   const cid = generateCorrelationId();
 *   logger.info("...", { correlationId: cid });
 */
export function generateCorrelationId(): string {
    return `cid_${randomUUID()}`;
}

/**
 * Extracts correlationId from event data, or generates a new one.
 * Used by downstream consumers (ledger, notifications) that receive
 * events from upstream producers (transfers).
 */
export function extractCorrelationId(eventData: Record<string, any>): string {
    return eventData?.correlationId || generateCorrelationId();
}
