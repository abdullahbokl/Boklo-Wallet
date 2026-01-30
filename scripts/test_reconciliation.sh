#!/bin/bash
set -e

if [ -z "$PROJECT_ID" ]; then
  # Default to dev project if not set, or error
  export PROJECT_ID="boklo-wallet"
fi

REGION="us-central1"
FUNCTION_NAME="triggerReconciliationNow"

echo "Triggering Reconciliation Report (HTTP)..."
# In a real authenticated scenario, you would need an ID token here.
# For now, assuming public or IAM-authorized invocation via gcloud or direct curl if public.
# Using 'gcloud functions call' is easiest for IAM auth.

# Generate URL
URL="https://$REGION-$PROJECT_ID.cloudfunctions.net/$FUNCTION_NAME"

# Store response
RESPONSE=$(curl -s -X POST "$URL" -H "Content-Type: application/json")
echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q '"message":"Reconciliation triggered successfully"'; then
  echo "PASS: Reconciliation triggered."
else
  echo "FAIL: Unexpected response"
  exit 1
fi

if echo "$RESPONSE" | grep -q '"status":"'; then
   STATUS=$(echo "$RESPONSE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
   echo "Report Status: $STATUS"
fi

echo "Done."
