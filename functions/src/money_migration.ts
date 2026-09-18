import * as admin from "firebase-admin";
import { defineSecret } from "firebase-functions/params";
import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { hasMinorUnitsFlag, toMinorUnits } from "./utils/money";

const db = admin.firestore();

interface MoneyFieldSpec {
  collection: string;
  /** Subcollection path is derived per parent doc when `parent` is set. */
  fields: string[];
}

const TOP_LEVEL_SPECS: MoneyFieldSpec[] = [
  { collection: "wallets", fields: ["balance"] },
  { collection: "transfers", fields: ["amount"] },
  { collection: "payment_requests", fields: ["amount"] },
];

const EVENTS_SPEC: MoneyFieldSpec = {
  collection: "events",
  fields: ["amount"],
};
const SUBCOLLECTIONS = ["transactions", "ledger"];

/**
 * Admin-only, idempotent migration: converts every monetary value from
 * floating-point major units to INTEGER MINOR UNITS (x100) and stamps the
 * `minorUnits: true` marker. Skips documents already carrying the marker,
 * so it is safe to run multiple times and after new (already-minor) writes.
 *
 * Runbook: docs/MONEY_MIGRATION.md — run immediately after deploying the
 * minor-units backend, before the client is used.
 */
export const migrateMoneyToMinorUnits = onCall(
  { region: "us-central1", timeoutSeconds: 540, maxInstances: 1 },
  async (request) => {
    if (!request.auth || request.auth.token.admin !== true) {
      throw new HttpsError(
        "permission-denied",
        "Only admins can run the money migration",
      );
    }

    return runMigration();
  },
);

/**
 * Ops-only HTTP variant for environments where minting an admin ID token
 * is impractical. Authenticated by the MIGRATION_TOKEN secret presented
 * as a Bearer header. Same idempotent logic as the callable.
 */
export const MIGRATION_TOKEN = defineSecret("MIGRATION_TOKEN");

export const migrateMoneyToMinorUnitsHttp = onRequest(
  {
    region: "us-central1",
    timeoutSeconds: 540,
    maxInstances: 1,
    secrets: [MIGRATION_TOKEN],
  },
  async (req, res) => {
    const header = req.headers.authorization ?? "";
    const presented = header.startsWith("Bearer ") ? header.slice(7) : "";
    // Trim: secrets set via stdin may carry a trailing newline.
    const expected = MIGRATION_TOKEN.value().trim();
    if (expected.length < 32 || presented.trim() !== expected) {
      res.status(403).json({ error: "Forbidden" });
      return;
    }

    const result = await runMigration();
    res.status(200).json(result);
  },
);

async function runMigration(): Promise<{
  success: boolean;
  converted: Record<string, number>;
}> {
  const summary: Record<string, number> = {};

  const convertDoc = (
    doc: admin.firestore.QueryDocumentSnapshot,
    fields: string[],
    batch: admin.firestore.WriteBatch,
  ): boolean => {
    const data = doc.data();
    if (hasMinorUnitsFlag(data)) {
      return false;
    }
    const updates: Record<string, unknown> = { minorUnits: true };
    let changed = false;
    for (const field of fields) {
      const value = data[field];
      if (typeof value === "number" && Number.isFinite(value)) {
        updates[field] = toMinorUnits(value);
        changed = true;
      }
    }
    if (!changed) {
      return false;
    }
    batch.update(doc.ref, updates);
    return true;
  };

  // 1. Top-level collections
  for (const spec of TOP_LEVEL_SPECS) {
    const snapshot = await db.collection(spec.collection).get();
    let converted = 0;
    for (let i = 0; i < snapshot.docs.length; i += 400) {
      const batch = db.batch();
      let touched = false;
      for (const doc of snapshot.docs.slice(i, i + 400)) {
        if (convertDoc(doc, spec.fields, batch)) {
          converted++;
          touched = true;
        }
      }
      if (touched) {
        await batch.commit();
      }
    }
    summary[spec.collection] = converted;
  }

  // 2. Events (audit stream)
  {
    const snapshot = await db.collection(EVENTS_SPEC.collection).get();
    let converted = 0;
    for (let i = 0; i < snapshot.docs.length; i += 400) {
      const batch = db.batch();
      let touched = false;
      for (const doc of snapshot.docs.slice(i, i + 400)) {
        const data = doc.data();
        if (data.amount === undefined) {
          continue; // events without monetary payloads stay untouched
        }
        if (convertDoc(doc, EVENTS_SPEC.fields, batch)) {
          converted++;
          touched = true;
        }
      }
      if (touched) {
        await batch.commit();
      }
    }
    summary.events = converted;
  }

  // 3. Per-wallet subcollections (transactions, ledger)
  for (const sub of SUBCOLLECTIONS) {
    const wallets = await db.collection("wallets").listDocuments();
    let converted = 0;
    for (const walletRef of wallets) {
      const snapshot = await walletRef.collection(sub).get();
      for (let i = 0; i < snapshot.docs.length; i += 400) {
        const batch = db.batch();
        let touched = false;
        for (const doc of snapshot.docs.slice(i, i + 400)) {
          if (convertDoc(doc, ["amount"], batch)) {
            converted++;
            touched = true;
          }
        }
        if (touched) {
          await batch.commit();
        }
      }
    }
    summary[sub] = converted;
  }

  logger.info("Money migration completed", {
    event: "MONEY_MIGRATION_COMPLETE",
    summary,
  });

  return { success: true, converted: summary };
}
