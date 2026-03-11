import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/features/notifications/domain/entities/notification_entity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    required this.notification,
    this.onMarkRead,
    this.onDelete,
    super.key,
  });

  final NotificationEntity notification;
  final VoidCallback? onMarkRead;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isRead = notification.status == NotificationStatus.read;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: _buildDismissBackground(scheme),
      child: GestureDetector(
        onTap: onMarkRead,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(AppDimens.md),
          decoration: BoxDecoration(
            color: isRead ? scheme.surface : scheme.primaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(
              color: isRead ? scheme.outlineVariant : scheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationIcon(type: notification.type, isRead: isRead),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm').format(notification.createdAt),
                          style: AppTypography.caption.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.xs),
                    Text(
                      notification.body,
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDismissBackground(ColorScheme scheme) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Icon(Icons.delete_outline_rounded, color: scheme.onError),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.type, required this.isRead});

  final String type;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    IconData iconData;
    Color iconColor;

    if (type.contains('SUCCESS')) {
      iconData = Icons.check_circle_outline_rounded;
      iconColor = Colors.green;
    } else if (type.contains('FAILED')) {
      iconData = Icons.error_outline_rounded;
      iconColor = scheme.error;
    } else if (type.contains('RECEIVED')) {
      iconData = Icons.account_balance_wallet_rounded;
      iconColor = scheme.primary;
    } else {
      iconData = Icons.notifications_active_rounded;
      iconColor = scheme.secondary;
    }

    return Container(
      padding: const EdgeInsets.all(AppDimens.sm),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: isRead ? iconColor.withValues(alpha: 0.5) : iconColor,
        size: 24,
      ),
    );
  }
}
