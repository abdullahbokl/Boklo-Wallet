export enum TransferEventType {
  CREATED = 'transaction.created',
  COMPLETED = 'transaction.completed',
  FAILED = 'transaction.failed',
}

export interface BaseEvent {
  eventId: string;
  eventType: TransferEventType;
  occurredAt: string; // ISO 8601
}

export interface TransferEventPayload {
  transactionId: string;
  senderWalletId: string;
  receiverWalletId: string;
  amount: number;
  currency: string;
}

export interface TransactionCreatedEvent extends BaseEvent, TransferEventPayload {
  eventType: TransferEventType.CREATED;
}

export interface TransactionCompletedEvent extends BaseEvent, TransferEventPayload {
  eventType: TransferEventType.COMPLETED;
}

export interface TransactionFailedEvent extends BaseEvent, TransferEventPayload {
  eventType: TransferEventType.FAILED;
  failureReason: string;
}

export type TransferEvent = 
  | TransactionCreatedEvent 
  | TransactionCompletedEvent 
  | TransactionFailedEvent;
