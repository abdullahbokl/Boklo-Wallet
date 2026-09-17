import 'dart:async';

import 'package:boklo/features/notifications/domain/entities/notification_entity.dart';
import 'package:boklo/features/notifications/domain/repositories/app_notif_repo_domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// App-wide unread notification count. Registered as a lazy singleton so
/// the wallet bell and the notification center share one subscription.
@lazySingleton
class UnreadNotificationsCubit extends Cubit<int> {
  UnreadNotificationsCubit(this._repository) : super(0);

  final AppNotificationRepository _repository;
  StreamSubscription<dynamic>? _subscription;
  String? _observedUserId;

  /// (Re)subscribes for the given user; no-op when already observing them.
  void observeUser(String? userId) {
    if (userId == null || userId == _observedUserId) return;
    _observedUserId = userId;
    unawaited(_subscription?.cancel());
    _subscription = _repository.observeNotifications().listen((result) {
      result.fold(
        (_) => emit(0),
        (notifications) {
          final unread = notifications
              .where(
                (n) => n.status != NotificationStatus.read,
              )
              .length;
          emit(unread);
        },
      );
    });
  }

  void reset() {
    _observedUserId = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    emit(0);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
