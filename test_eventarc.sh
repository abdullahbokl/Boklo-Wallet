#!/bin/bash
URL="http://127.0.0.1:9299/v1/projects/boklo-wallet/locations/us-central1/channels/firebase:publishEvents"

curl -v -X POST "$URL" \
-H "Content-Type: application/json" \
-d '{
  "events": [
    {
      "@type": "type.googleapis.com/io.cloudevents.v1.CloudEvent",
      "id": "test-manual-1",
      "source": "//boklo.wallet/transfers",
      "spec_version": "1.0",
      "type": "transaction.created",
      "text_data": "{\"transactionId\":\"test-tx-manual\",\"eventType\":\"transaction.created\"}",
      "attributes": {
        "datacontenttype": { "ce_string": "application/json" }
      }
    }
  ]
}'
