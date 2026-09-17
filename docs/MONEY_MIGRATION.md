# Money Representation Migration — Runbook

## Target representation

All monetary values in Firestore are **integer minor units** (piastres for
EGP: `105000` = EGP 1,050.00). Every document carrying money is stamped with
`minorUnits: true`. Floating-point money is eliminated end-to-end:

| Collection | Field | Representation |
| --- | --- | --- |
| `wallets` | `balance` | int minor units + `minorUnits: true` |
| `transfers` | `amount` | int minor units + `minorUnits: true` |
| `payment_requests` | `amount` | int minor units |
| `wallets/{id}/transactions` | `amount` | int minor units |
| `wallets/{id}/ledger` | `amount` | int minor units |
| `events` | `amount` | int minor units (when present) |
| BigQuery `transfers` / `ledger_entries` | `amount` | INT64 minor units |

## Safety mechanisms

1. **Fail-closed execution** — `onTransferCreated` refuses (marks the
   transfer `failed` with `wallet-not-migrated-to-minor-units`) if either
   wallet lacks the `minorUnits` marker. A major-unit balance can therefore
   never be interpreted as minor units (which would 100× it).
2. **Idempotent migration** — `migrateMoneyToMinorUnits` (admin-claimed
   callable) converts every un-flagged money document (`x100`, rounded) and
   stamps the marker. It is safe to run multiple times: flagged documents
   are skipped.
3. **New writes are already minor** — client transfer creation
   (`TransferModel.toJson`) and all server writers set the marker.

## Deploy order

```bash
# 1. Deploy the backend (includes the migration callable and the
#    fail-closed guard; new transfers fail safely until step 2 completes)
firebase deploy --only functions

# 2. Obtain an admin ID token for an admin user
#    (one-time: admin.auth().setCustomUserClaims(uid, { admin: true }))

# 3. Run the migration and verify the summary counts
ADMIN_ID_TOKEN=<token> node scripts/money_migration_check.js   # pre-counts (optional)
curl -X POST "https://us-central1-<project>.cloudfunctions.net/migrateMoneyToMinorUnits" \
     -H "Authorization: Bearer $ADMIN_ID_TOKEN" -H "Content-Type: application/json" -d '{}'

# 4. Update Remote Config fraud limits to minor units (one-time):
#      fraud_amount_single: 500000     (= EGP 5,000.00)
#      fraud_amount_24h:    1000000    (= EGP 10,000.00)
#    (velocity/failure-rate limits are counts — unchanged)

# 5. Deploy the client build that speaks minor units (this repository).

# 6. Re-run the migration once more (no-op verification: all counts zero).
```

## Rollback

Restoring floating-point money is **not supported** by design — the integer
representation is strictly more precise. To roll back the *code*, deploy the
previous backend revision; historical documents remain valid minor-unit
integers for any future re-migration (the migration only ever widens).

## Verification queries (Firestore / console)

- Any money document with `minorUnits != true` → must be zero after step 3.
- `wallets` balance parity: sum of `wallets/{id}/transactions` amounts
  (CREDIT − DEBIT) must equal the wallet `balance` (the scheduled
  `reconcileWallets` job reports exactly this).
