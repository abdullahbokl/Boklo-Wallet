import * as admin from "firebase-admin";

const db = admin.firestore();

export interface WalletPublicProfile {
  id: string;
  ownerName: string;
  username: string | null;
  alias: string | null;
  currency: string;
  isActive: boolean;
}

/**
 * Maintains the `wallet_public/{walletId}` document: the ONLY wallet-derived
 * data other users may see. Balances and owner emails must never be written
 * here. Call after any write that changes the public fields.
 */
export async function syncWalletPublic(
  walletId: string,
  overrides: Partial<WalletPublicProfile> = {},
): Promise<void> {
  const snap = await db.collection("wallets").doc(walletId).get();
  const data = snap.data() ?? {};

  const profile: WalletPublicProfile = {
    id: walletId,
    ownerName: (overrides.ownerName ?? data.ownerName ?? "") as string,
    username: (overrides.username ?? data.username ?? null) as string | null,
    alias: (overrides.alias ?? data.alias ?? null) as string | null,
    currency: (overrides.currency ?? data.currency ?? "EGP") as string,
    isActive: (overrides.isActive ?? data.isActive ?? true) as boolean,
  };

  await db.collection("wallet_public").doc(walletId).set({
    ...profile,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

/** Same as {@link syncWalletPublic} but usable inside a transaction. */
export function syncWalletPublicInTxn(
  t: admin.firestore.Transaction,
  walletId: string,
  overrides: Partial<Omit<WalletPublicProfile, "id">> = {},
): void {
  t.set(db.collection("wallet_public").doc(walletId), {
    id: walletId,
    ...overrides,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}
