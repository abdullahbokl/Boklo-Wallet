import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

export const onEventCreated = onDocumentCreated("events/{eventId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.warn("No data associated with event");
    return;
  }

  const eventData = snapshot.data();
  const eventId = event.params.eventId;

  const projectId = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
  const location = "us-central1"; 
  const channel = `projects/${projectId}/locations/${location}/channels/firebase`;
  const url = `https://eventarcpublishing.googleapis.com/v1/${channel}:publishEvents`;

  logger.info(`Publishing event ${eventId} (${eventData.eventType}) to Eventarc channel: ${channel}`);

  try {
    const token = await admin.credential.applicationDefault().getAccessToken();
    
    // Construct the CloudEvent in Protobuf JSON format
    const payload = {
      events: [
        {
          "@type": "type.googleapis.com/io.cloudevents.v1.CloudEvent",
          "id": eventId,
          "source": "//boklo.wallet/transfers",
          "spec_version": "1.0",
          "type": eventData.eventType,
          "text_data": JSON.stringify(eventData),
          "attributes": {
            "datacontenttype": { "ce_string": "application/json" }
          }
        }
      ]
    };

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${token.access_token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`HTTP ${response.status}: ${text}`);
    }

    logger.info(`Successfully published event: ${eventData.eventType}`);
  } catch (error) {
    logger.error("Failed to publish event to Eventarc", error);
  }
});
