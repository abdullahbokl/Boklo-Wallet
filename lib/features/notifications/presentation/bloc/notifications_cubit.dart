import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/notifications/domain/entities/notification_entity.dart';
import 'package:boklo/features/notifications/domain/repositories/app_notif_repo_domain.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

part 'notifications_state.dart';

@injectable
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsInitial());

  final AppNotificationRepository _repository;
  StreamSubscription<Either<Failure, List<NotificationEntity>>>? _subscription;

  void observeNotifications() {
    emit(const NotificationsLoading());
    _subscription?.cancel();
    _subscription = _repository.observeNotifications().listen(
      (result) {
        result.fold(
          (failure) => emit(NotificationsError(failure.message)),
          (notifications) => emit(NotificationsLoaded(notifications)),
        );
      },
      onError: (error) {
        emit(NotificationsError(error.toString()));
      },
    );
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
  }

  Future<void> deleteNotification(String id) async {
    await _repository.deleteNotification(id);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
