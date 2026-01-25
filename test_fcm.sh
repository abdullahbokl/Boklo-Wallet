#!/bin/bash

# Configuration
PROJECT_ID="boklo-wallet"
ACCESS_TOKEN="YOUR_ACCESS_TOKEN_HERE"
FCM_ENDPOINT="https://fcm.googleapis.com/v1/projects/$PROJECT_ID/messages:send"
TARGET_TOKEN="cEJTNAyGQgGMHred6IFmlj:APA91bGRe9X05Hmp0OpFX6oPIx7uOKr-D6CdjCIjPky5W7-uthzqrNdObpAyheVEmWatC5IDKiEhyqTlr3nt4n3qjmroxAG5z8R70b_2eU-v34LDk2LgRwQ"

PAYLOAD='{
  "message": {
    "token": "'"$TARGET_TOKEN"'",
    "notification": {
      "title": "Boklo Wallet Test",
      "body": "This is a direct test message from the script."
    },
    "data": {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "transactionId": "test_tx_123",
      "status": "completed"
    },
    "android": {
      "priority": "high",
      "notification": {
         "channel_id": "high_importance_channel"
      }
    },
    "apns": {
      "payload": {
        "aps": {
          "content-available": 1
        }
      }
    }
  }
}'

echo "Sending FCM message..."
echo "Endpoint: $FCM_ENDPOINT"
echo "Target: $TARGET_TOKEN"

curl -X POST -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: application/json" -d "$PAYLOAD" "$FCM_ENDPOINT"

echo -e "\nDone."
