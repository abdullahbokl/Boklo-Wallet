import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { extractCorrelationId } from "./utils/correlation";

const db = admin.firestore();

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

  const correlationId = extractCorrelationId(eventData);

  logger.info("Event publishing started", {
    event: "EVENT_PUBLISH",
    status: "STARTED",
    eventId: eventId,
    eventType: eventData.eventType,
    transactionId: eventData.transactionId,
    correlationId
  });

  const startTime = Date.now();
  const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";
  const eventTime = eventData.occurredAt || new Date().toISOString();

  const publishEvent = async (): Promise<void> => {
    const token = await admin.credential.applicationDefault().getAccessToken();
    
    // The emulator expects camelCase (specVersion, textData, ceString)
    // Production expects snake_case (spec_version, text_data, ce_string)
    const payload = {
      events: [
        isEmulator ? {
          "@type": "type.googleapis.com/io.cloudevents.v1.CloudEvent",
          "id": eventId,
          "source": "//boklo.wallet/transfers",
          "specVersion": "1.0",
          "type": eventData.eventType,
          "textData": JSON.stringify(eventData),
          "attributes": {
            "datacontenttype": { "ceString": "application/json" },
            "time": { "ceTimestamp": eventTime }
          }
        } : {
          "@type": "type.googleapis.com/io.cloudevents.v1.CloudEvent",
          "id": eventId,
          "source": "//boklo.wallet/transfers",
          "spec_version": "1.0",
          "type": eventData.eventType,
          "text_data": JSON.stringify(eventData),
          "attributes": {
            "datacontenttype": { "ce_string": "application/json" },
            "time": { "ce_timestamp": eventTime }
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
  };

  try {
    await publishEvent();

    logger.info("Event published successfully", {
      event: "EVENT_PUBLISH",
      status: "COMPLETED",
      eventId: eventId,
      eventType: eventData.eventType,
      transactionId: eventData.transactionId,
      durationMs: Date.now() - startTime
    });
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : JSON.stringify(error);
    logger.error("Event publishing failed", {
      event: "EVENT_PUBLISH",
      status: "FAILED",
      eventId: eventId,
      eventType: eventData.eventType,
      transactionId: eventData.transactionId,
      error: errorMessage,
      durationMs: Date.now() - startTime
    });

    // Reliability: bounded retry with exponential backoff, then a
    // persisted dead-letter alert (never silently lost).
    const MAX_ATTEMPTS = 3;
    const eventRef = db.collection("events").doc(eventId);
    let attempts = 0;
    let lastError = errorMessage;

    while (attempts < MAX_ATTEMPTS) {
      attempts++;
      await new Promise((resolve) => setTimeout(resolve, 1000 * attempts));
      try {
        await publishEvent();
        logger.info("Event published on retry", {
          event: "EVENT_PUBLISH_RETRY_OK",
          eventId,
          attempt: attempts,
        });
        return;
      } catch (retryError) {
        lastError =
          retryError instanceof Error
            ? retryError.message
            : JSON.stringify(retryError);
      }
    }

    await eventRef.set(
      {
        publishFailed: true,
        publishAttempts: attempts,
        publishLastError: lastError,
      },
      { merge: true },
    );
    await db.collection("ops_alerts").doc(`event_publish_${eventId}`).set({
      type: "EVENT_PUBLISH_DEAD_LETTER",
      eventId,
      eventType: eventData.eventType,
      transactionId: eventData.transactionId,
      attempts,
      lastError,
      status: "OPEN",
      createdAt: new Date(),
    });
    logger.error("Event dead-lettered after retries", {
      event: "EVENT_PUBLISH_DEAD_LETTER",
      eventId,
      attempts,
    });
  }
});
