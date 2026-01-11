import { onCustomEventPublished } from "firebase-functions/v2/eventarc";
import * as logger from "firebase-functions/logger";

export const onTransactionCompletedLog = onCustomEventPublished(
    "transaction.completed", 
    (event) => {
        logger.info("SMOKE TEST: Received transaction.completed event", {
            eventId: event.id,
            data: event.data,
            source: event.source,
            type: event.type
        });
    }
);
