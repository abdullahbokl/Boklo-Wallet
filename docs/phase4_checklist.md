# Phase 4 Deployment Checklist

## 1. BigQuery Setup (Automated)

Run the bootstrap script to create the `boklo_analytics` dataset and enforce schema tables (`transfers`, `ledger_entries`) idempotently.

```bash
export PROJECT_ID="your-project-id"
./scripts/bigquery_bootstrap.sh
```

## 2. Environment Variables

- [ ] `BIGQUERY_DATASET`: Set if different from `boklo_analytics`.
- [ ] `RISK_MODE`: Set to `ENFORCE` for production blocking, `MONITOR` for logging only.

## 3. Verification

Run the verification script to confirm tables are created and queryable.

```bash
export PROJECT_ID="your-project-id"
./scripts/bigquery_verify.sh
```

## 4. Reconciliation

- [ ] Manual Trigger Verification:
  ```bash
  ./scripts/test_reconciliation.sh
  ```
- [ ] Verify `reconciliation_reports` collection in Firestore.

## 5. Event Replay Tests

- [ ] Create `admin_jobs` doc to test replay safely.
- [ ] Check logs for replay activity.
