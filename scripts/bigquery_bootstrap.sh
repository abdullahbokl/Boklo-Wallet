#!/bin/bash
set -e

if [ -z "$PROJECT_ID" ]; then
    echo "Error: PROJECT_ID environment variable is not set."
    echo "Usage: export PROJECT_ID='your-project-id'; ./scripts/bigquery_bootstrap.sh"
    exit 1
fi

echo "Using Project ID: $PROJECT_ID"

echo "Enabling BigQuery API..."
gcloud services enable bigquery.googleapis.com --project="$PROJECT_ID"

DATASET_ID="boklo_analytics"
LOCATION="us-central1"

echo "Checking Dataset: $DATASET_ID..."
if ! bq show --project_id="$PROJECT_ID" "$DATASET_ID" >/dev/null 2>&1; then
    echo "Creating dataset $DATASET_ID..."
    bq --project_id="$PROJECT_ID" mk --dataset --location="$LOCATION" "$DATASET_ID"
else
    echo "Dataset $DATASET_ID already exists."
fi

# Create transfers table
TABLE_ID="$DATASET_ID.transfers"
SCHEMA_FILE="docs/bigquery/transfers.schema.json"
echo "Checking Table: $TABLE_ID..."
if ! bq show --project_id="$PROJECT_ID" "$TABLE_ID" >/dev/null 2>&1; then
    echo "Creating table $TABLE_ID..."
    bq mk --table --project_id="$PROJECT_ID" "$TABLE_ID" "$SCHEMA_FILE"
else
    echo "Table $TABLE_ID already exists."
fi

# Create ledger_entries table
TABLE_ID="$DATASET_ID.ledger_entries"
SCHEMA_FILE="docs/bigquery/ledger_entries.schema.json"
echo "Checking Table: $TABLE_ID..."
if ! bq show --project_id="$PROJECT_ID" "$TABLE_ID" >/dev/null 2>&1; then
    echo "Creating table $TABLE_ID..."
    bq mk --table --project_id="$PROJECT_ID" "$TABLE_ID" "$SCHEMA_FILE"
else
    echo "Table $TABLE_ID already exists."
fi

echo "BigQuery Bootstrap Complete."
