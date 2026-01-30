# BigQuery Schema

Dataset: `boklo_analytics` (Location: matching Firestore, usually `us-central1`)

## Table: `transfers`

Tracks global transfer intents and statuses.

| Field            | Type      | Description                       |
| ---------------- | --------- | --------------------------------- |
| `transfer_id`    | STRING    | Unique ID of the transfer request |
| `from_wallet_id` | STRING    | Sender Wallet ID                  |
| `to_wallet_id`   | STRING    | Receiver Wallet ID                |
| `amount`         | FLOAT     | Amount transferred                |
| `currency`       | STRING    | Currency code (USD, etc.)         |
| `status`         | STRING    | `pending`, `completed`, `failed`  |
| `timestamp`      | TIMESTAMP | Record creation time              |
| `risk_level`     | STRING    | Fraud risk assessment level       |
| `ingest_time`    | TIMESTAMP | Time of ingestion into BigQuery   |

## Table: `ledger_entries`

Tracks immutable financial movements (credits/debits). Source of Truth for analytical reporting.

| Field         | Type      | Description                     |
| ------------- | --------- | ------------------------------- |
| `entry_id`    | STRING    | Unique Ledger Entry ID          |
| `wallet_id`   | STRING    | Wallet ID owning this entry     |
| `transfer_id` | STRING    | Associated Transfer ID          |
| `amount`      | FLOAT     | Amount (absolute value)         |
| `direction`   | STRING    | `CREDIT` or `DEBIT`             |
| `description` | STRING    | User-facing description         |
| `timestamp`   | TIMESTAMP | Entry timestamp                 |
| `ingest_time` | TIMESTAMP | Time of ingestion into BigQuery |
