import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/features/notifications/presentation/bloc/notifications_cubit.dart';
import 'package:boklo/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:boklo/shared/widgets/molecules/app_empty_state.dart';
import 'package:boklo/shared/widgets/molecules/app_page_scaffold.dart';
import 'package:boklo/shared/widgets/molecules/wallet_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NotificationsCubit>()..observeNotifications(),
      child: const NotificationsView(),
    );
  }
}

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Notifications',
      child: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationsError) {
            return WalletErrorView(
              title: state.message,
              onRetry: () => context.read<NotificationsCubit>().observeNotifications(),
            );
          }

          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return const AppEmptyState(
                title: 'No notifications yet',
                subtitle: 'Important account activity and transfer updates appear here.',
                icon: Icons.notifications_none_rounded,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.only(top: AppDimens.md, bottom: AppDimens.xxl),
              itemCount: state.notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppDimens.sm),
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return NotificationTile(
                  notification: notification,
                  onDelete: () => context
                      .read<NotificationsCubit>()
                      .deleteNotification(notification.id),
                  onMarkRead: () => context
                      .read<NotificationsCubit>()
                      .markAsRead(notification.id),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
