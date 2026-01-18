#!/bin/bash

# Configuration
PROJECT_ID="boklo-wallet"
ACCESS_TOKEN="YOUR_ACCESS_TOKEN_HERE"
FCM_ENDPOINT="https://fcm.googleapis.com/v1/projects/$PROJECT_ID/messages:send"
TARGET_TOKEN="ejqcCSlIQfiOlZQ5YBxVhG:APA91bHK27vhZMe_d0jZrIN8duw0Iy7-Ft-ckT37vN_NBu-Dx-HIbyIKUOdvmtFujtW4hadrXlgPpJAFSbHJI80Jv5JrZR9Gst1KRfoemTdwsz1QvORK4_8"

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
