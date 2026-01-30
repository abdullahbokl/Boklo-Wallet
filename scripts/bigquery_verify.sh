#!/bin/bash
set -e

if [ -z "$PROJECT_ID" ]; then
    echo "Error: PROJECT_ID environment variable is not set."
    echo "Usage: export PROJECT_ID='your-project-id'; ./scripts/bigquery_verify.sh"
    exit 1
fi

echo "Verifying BigQuery setup for Project ID: $PROJECT_ID"

# Simple query to check if tables exist and are queryable
echo "Checking transfers table..."
bq query --use_legacy_sql=false --project_id="$PROJECT_ID" "SELECT count(*) as count FROM \`$PROJECT_ID.boklo_analytics.transfers\` LIMIT 1"

echo "Checking ledger_entries table..."
bq query --use_legacy_sql=false --project_id="$PROJECT_ID" "SELECT count(*) as count FROM \`$PROJECT_ID.boklo_analytics.ledger_entries\` LIMIT 1"

echo "Verification Successful!"
