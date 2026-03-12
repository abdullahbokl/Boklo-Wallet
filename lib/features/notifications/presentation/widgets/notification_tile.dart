import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/features/notifications/domain/entities/notification_entity.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
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
    final tone = _toneForType(notification.type, scheme);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Icon(Icons.delete_outline_rounded, color: scheme.onError),
      ),
      child: AppCard(
        onTap: onMarkRead,
        padding: const EdgeInsets.all(AppDimens.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.sm),
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconForType(notification.type),
                color: tone.withValues(alpha: isRead ? 0.7 : 1),
                size: AppDimens.iconMd,
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTypography.subtitle.copyWith(
                            color: scheme.onSurface,
                            fontWeight:
                                isRead ? FontWeight.w500 : FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(notification.createdAt),
                        style: AppTypography.caption.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.xs),
                  Text(
                    notification.body,
                    style: AppTypography.bodyMedium.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _toneForType(String type, ColorScheme scheme) {
    if (type.contains('SUCCESS')) return Colors.green.shade700;
    if (type.contains('FAILED')) return scheme.error;
    if (type.contains('RECEIVED')) return scheme.primary;
    return scheme.secondary;
  }

  IconData _iconForType(String type) {
    if (type.contains('SUCCESS')) return Icons.check_circle_outline_rounded;
    if (type.contains('FAILED')) return Icons.error_outline_rounded;
    if (type.contains('RECEIVED')) return Icons.account_balance_wallet_outlined;
    return Icons.notifications_active_outlined;
  }
}
