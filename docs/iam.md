# IAM Roles & Permissions

To limit attack surface, the App Engine default service account (used by Cloud Functions) requires the following permissions. Consider using a custom service account for tighter security.

## Required Roles

1.  **BigQuery Data Editor** (`roles/bigquery.dataEditor`)
    - Required for `streamTransferToBigQuery` and `streamLedgerToBigQuery`.
    - Allows inserting rows into `boklo_analytics` dataset.

2.  **Secret Manager Secret Accessor** (`roles/secretmanager.secretAccessor`)
    - Required if using `defineSecret` for API keys (e.g. `PAYMOB_API_KEY`).

3.  **Cloud Datastore User** (`roles/datastore.user`)
    - Standard Firestore read/write access.

4.  **Eventarc Event Receiver** (`roles/eventarc.eventReceiver`)
    - Required for Eventarc triggers.

## Service Accounts

- **Default**: `PROJECT_ID@appspot.gserviceaccount.com` (Currently used)
- **Recommendation**: Create `boklo-backend-faas@PROJECT_ID.iam.gserviceaccount.com` with only above roles.
