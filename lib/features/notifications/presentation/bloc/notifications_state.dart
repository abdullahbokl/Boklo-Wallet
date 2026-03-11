part of 'notifications_cubit.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded(this.notifications);
  final List<NotificationEntity> notifications;

  @override
  List<Object?> get props => [notifications];
}

class NotificationsError extends NotificationsState {
  const NotificationsError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
