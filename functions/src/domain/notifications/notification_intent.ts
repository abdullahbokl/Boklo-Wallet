
import { TransferEventType } from "../events/transfer_events";

// Represents the intent to send a notification
export interface NotificationIntent {
    // Unique ID for idempotency
    notificationId: string;

    // The user to notify
    userId: string; // Derived from walletId

    // The type of notification (mapped from event type)
    type: NotificationType;

    // Data required to construct the message
    payload: {
        titleKey: string;
        bodyKey: string;
        data: Record<string, string>; // Dynamic values for the template
    };
}

export enum NotificationType {
    TRANSFER_RECEIVED = 'TRANSFER_RECEIVED',
    TRANSFER_SENT_SUCCESS = 'TRANSFER_SENT_SUCCESS',
    TRANSFER_FAILED = 'TRANSFER_FAILED',
}

// Maps domain events to notification intents
export const EventNotificationMap: Record<TransferEventType, NotificationType[]> = {
    [TransferEventType.COMPLETED]: [
        NotificationType.TRANSFER_RECEIVED,      // Notify Receiver
        NotificationType.TRANSFER_SENT_SUCCESS   // Notify Sender
    ],
    [TransferEventType.FAILED]: [
        NotificationType.TRANSFER_FAILED         // Notify Sender
    ],
    [TransferEventType.CREATED]: [], // No notification for created
};
