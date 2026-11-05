/**
 * Firestore security-rules tests against the emulator.
 *
 * Run with the emulator up: `firebase emulators:exec --only firestore "npm run test:rules"`
 * (see package.json). Covers the security-critical invariants: balance
 * privacy, backend-authoritative money writes, identifier anti-enumeration.
 */
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { afterAll, beforeAll, describe, it } from "@jest/globals";
import { doc, getDoc, setDoc, updateDoc, deleteDoc } from "firebase/firestore";
import * as fs from "node:fs";

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "rules-test-boklo",
    firestore: {
      rules: fs.readFileSync("../firestore.rules", "utf8"),
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

const ALICE = "alice-uid";
const BOB = "bob-uid";

function aliceDb() {
  return testEnv.authenticatedContext(ALICE).firestore();
}
function bobDb() {
  return testEnv.authenticatedContext(BOB).firestore();
}
function anonDb() {
  return testEnv.unauthenticatedContext().firestore();
}

describe("users + subcollections", () => {
  it("owner can read own profile; others cannot", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "users", ALICE), { email: "a@x.com" });
    });
    await assertSucceeds(getDoc(doc(aliceDb(), "users", ALICE)));
    await assertFails(getDoc(doc(bobDb(), "users", ALICE)));
    await assertFails(getDoc(doc(anonDb(), "users", ALICE)));
  });

  it("clients cannot create or update user profiles (backend-authoritative)", async () => {
    await assertFails(setDoc(doc(aliceDb(), "users", ALICE), { email: "x" }));
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "users", ALICE), { email: "a@x.com" });
    });
    await assertFails(updateDoc(doc(aliceDb(), "users", ALICE), { email: "y" }));
  });

  it("owner manages own FCM tokens; other users cannot", async () => {
    await assertSucceeds(
      setDoc(doc(aliceDb(), "users", ALICE, "tokens", "tok1"), { token: "t" }),
    );
    await assertFails(
      setDoc(doc(bobDb(), "users", ALICE, "tokens", "tok2"), { token: "t" }),
    );
  });

  it("owner manages own contacts; other users cannot", async () => {
    await assertSucceeds(
      setDoc(doc(aliceDb(), "users", ALICE, "contacts", BOB), { uid: BOB }),
    );
    await assertFails(
      setDoc(doc(bobDb(), "users", ALICE, "contacts", "c"), { uid: "c" }),
    );
  });
});

describe("wallet privacy", () => {
  it("balances are owner-only: other users and anonymous are denied", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "wallets", ALICE), {
        balance: 100000,
        currency: "EGP",
      });
    });
    await assertSucceeds(getDoc(doc(aliceDb(), "wallets", ALICE)));
    await assertFails(getDoc(doc(bobDb(), "wallets", ALICE)));
    await assertFails(getDoc(doc(anonDb(), "wallets", ALICE)));
  });

  it("wallet create/delete is backend-only; update cannot touch balance/currency", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "wallets", ALICE), {
        id: ALICE,
        balance: 100000,
        currency: "EGP",
        alias: "alice",
      });
    });
    await assertFails(setDoc(doc(aliceDb(), "wallets", "new"), { balance: 0 }));
    await assertFails(deleteDoc(doc(aliceDb(), "wallets", ALICE)));
    await assertFails(
      updateDoc(doc(aliceDb(), "wallets", ALICE), { balance: 999999 }),
    );
    await assertFails(
      updateDoc(doc(aliceDb(), "wallets", ALICE), { currency: "USD" }),
    );
  });

  it("transactions and ledger are backend-only writes, owner-only reads", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "wallets", ALICE, "transactions", "t1"), {
        amount: 100,
      });
      await setDoc(doc(ctx.firestore(), "wallets", ALICE, "ledger", "l1"), {
        amount: 100,
      });
    });
    await assertSucceeds(
      getDoc(doc(aliceDb(), "wallets", ALICE, "transactions", "t1")),
    );
    await assertFails(getDoc(doc(bobDb(), "wallets", ALICE, "transactions", "t1")));
    await assertFails(
      setDoc(doc(aliceDb(), "wallets", ALICE, "transactions", "t2"), {
        amount: 1,
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb(), "wallets", ALICE, "ledger", "l2"), { amount: 1 }),
    );
  });
});

describe("transfers", () => {
  const validTransfer = {
    id: "transfer-1",
    fromWalletId: ALICE,
    toWalletId: BOB,
    amount: 5000,
    minorUnits: true,
    currency: "EGP",
    status: "pending",
    createdAt: 1_700_000_000,
  };

  it("sender can create a pending minor-units transfer", async () => {
    await assertSucceeds(
      setDoc(doc(aliceDb(), "transfers", "transfer-1"), validTransfer),
    );
  });

  it("rejects spoofed sender, non-pending status, float money, missing minorUnits", async () => {
    await assertFails(
      setDoc(doc(aliceDb(), "transfers", "t-bad-1"), {
        ...validTransfer,
        fromWalletId: BOB, // spoofed sender
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb(), "transfers", "t-bad-2"), {
        ...validTransfer,
        status: "completed",
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb(), "transfers", "t-bad-3"), {
        ...validTransfer,
        amount: 50.5, // float money
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb(), "transfers", "t-bad-4"), {
        ...validTransfer,
        minorUnits: false,
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb(), "transfers", "t-bad-5"), {
        ...validTransfer,
        extraField: true, // schema enforcement
      }),
    );
  });

  it("both parties can read; outsiders cannot; updates are backend-only", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "transfers", "tr-done"), {
        ...validTransfer,
        status: "completed",
      });
    });
    await assertSucceeds(getDoc(doc(aliceDb(), "transfers", "tr-done")));
    await assertSucceeds(getDoc(doc(bobDb(), "transfers", "tr-done")));
    await testEnv
      .authenticatedContext("carol")
      .firestore();
    await assertFails(
      getDoc(
        doc(testEnv.authenticatedContext("carol").firestore(), "transfers", "tr-done"),
      ),
    );
    await assertFails(
      updateDoc(doc(aliceDb(), "transfers", "tr-done"), { status: "pending" }),
    );
  });
});

describe("identifier lookups (anti-enumeration)", () => {
  it("exact get allowed for authenticated users; list denied", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "wallet_identifiers", "email:a@x.com"), {
        walletId: ALICE,
      });
    });
    await assertSucceeds(
      getDoc(doc(bobDb(), "wallet_identifiers", "email:a@x.com")),
    );
    // list is denied even for the same authenticated user
    const { collection, getDocs } = await import("firebase/firestore");
    await assertFails(getDocs(collection(bobDb(), "wallet_identifiers")));
  });
});

describe("newer collections", () => {
  it("scheduled_transfers: owner reads, nobody writes", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "scheduled_transfers", "s1"), {
        fromWalletId: ALICE,
        amount: 100,
      });
    });
    await assertSucceeds(getDoc(doc(aliceDb(), "scheduled_transfers", "s1")));
    await assertFails(getDoc(doc(bobDb(), "scheduled_transfers", "s1")));
    await assertFails(
      setDoc(doc(aliceDb(), "scheduled_transfers", "s2"), {
        fromWalletId: ALICE,
      }),
    );
  });

  it("fx_rates: authenticated read, no client writes", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "fx_rates", "EGP_USD"), {
        rateNum: 325,
        rateDen: 10,
      });
    });
    await assertSucceeds(getDoc(doc(aliceDb(), "fx_rates", "EGP_USD")));
    await assertFails(
      setDoc(doc(aliceDb(), "fx_rates", "EGP_USD"), { rateNum: 1, rateDen: 1 }),
    );
  });

  it("global ledger and events are fully client-denied", async () => {
    await assertFails(getDoc(doc(aliceDb(), "ledger", "x")));
    await assertFails(getDoc(doc(aliceDb(), "events", "x")));
  });

  it("payment_requests: parties read, others cannot; updates backend-only", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "payment_requests", "pr1"), {
        requesterId: ALICE,
        payerId: BOB,
        status: "PENDING",
      });
    });
    await assertSucceeds(getDoc(doc(aliceDb(), "payment_requests", "pr1")));
    await assertSucceeds(getDoc(doc(bobDb(), "payment_requests", "pr1")));
    await assertFails(
      getDoc(
        doc(testEnv.authenticatedContext("carol").firestore(), "payment_requests", "pr1"),
      ),
    );
    await assertFails(
      updateDoc(doc(bobDb(), "payment_requests", "pr1"), { status: "ACCEPTED" }),
    );
  });
});
