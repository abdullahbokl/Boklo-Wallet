#!/bin/bash
set -e

if [ -z "$PROJECT_ID" ]; then
  # Default to dev project if not set, or error
  export PROJECT_ID="boklo-wallet"
fi

REGION="us-central1"
FUNCTION_NAME="triggerReconciliationNow"

echo "Triggering Reconciliation Report (HTTP)..."
# The endpoint now REQUIRES a Firebase ID token carrying the `admin`
# custom claim (Authorization: Bearer <idToken>). Obtain one for an
# admin user (e.g. via the client app or a custom minting script) and
# export it as ADMIN_ID_TOKEN before running this script.

# Generate URL
URL="https://$REGION-$PROJECT_ID.cloudfunctions.net/$FUNCTION_NAME"

# Store response
if [ -z "${ADMIN_ID_TOKEN:-}" ]; then
  echo "ERROR: ADMIN_ID_TOKEN env var is required (admin-claimed Firebase ID token)."
  exit 1
fi

RESPONSE=$(curl -s -X POST "$URL" -H "Content-Type: application/json" -H "Authorization: Bearer $ADMIN_ID_TOKEN")
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
