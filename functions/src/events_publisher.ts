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
  let url = `https://eventarcpublishing.googleapis.com/v1/${channel}:publishEvents`;

  if (process.env.FUNCTIONS_EMULATOR === "true") {
      const eventarcPort = 9299; 
      // Emulator doesn't use /v1 prefix for publishEvents
      url = `http://127.0.0.1:${eventarcPort}/${channel}:publishEvents`;
      logger.info(`[Emulator] Redirecting Eventarc publish to ${url}`);
  }

  logger.info("Event publishing started", {
    event: "EVENT_PUBLISH",
    status: "STARTED",
    eventId: eventId,
    eventType: eventData.eventType,
    transactionId: eventData.transactionId
  });

  const startTime = Date.now();

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

    logger.info("Event published successfully", {
      event: "EVENT_PUBLISH",
      status: "COMPLETED",
      eventId: eventId,
      eventType: eventData.eventType,
      transactionId: eventData.transactionId,
      durationMs: Date.now() - startTime
    });
  } catch (error) {
    logger.error("Event publishing failed", {
      event: "EVENT_PUBLISH",
      status: "FAILED",
      eventId: eventId,
      eventType: eventData.eventType,
      transactionId: eventData.transactionId,
      error: error instanceof Error ? error.message : JSON.stringify(error),
      durationMs: Date.now() - startTime
    });
  }
});
