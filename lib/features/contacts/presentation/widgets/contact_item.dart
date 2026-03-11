import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/features/contacts/domain/entity/contact_entity.dart';
import 'package:boklo/shared/widgets/atoms/app_avatar.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:flutter/material.dart';

class ContactItem extends StatelessWidget {
  const ContactItem({
    super.key,
    required this.contact,
    this.onTap,
    this.onSendMoney,
    this.onRequestMoney,
    this.onRemove,
    this.isPickMode = false,
  });

  final ContactEntity contact;
  final VoidCallback? onTap;
  final VoidCallback? onSendMoney;
  final VoidCallback? onRequestMoney;
  final VoidCallback? onRemove;
  final bool isPickMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.md),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppDimens.md),
        child: Row(
          children: [
            AppAvatar(
              photoUrl: contact.photoUrl,
              name: contact.displayName,
              size: 48,
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.displayName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    contact.email,
                    style: AppTypography.caption.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (!isPickMode)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                onSelected: (value) {
                  if (value == 'send') onSendMoney?.call();
                  if (value == 'request') onRequestMoney?.call();
                  if (value == 'remove') onRemove?.call();
                },
                itemBuilder: (context) => [
                  _buildMenuItem(
                    context,
                    'send',
                    Icons.send_rounded,
                    'Send Money',
                  ),
                  _buildMenuItem(
                    context,
                    'request',
                    Icons.request_page_rounded,
                    'Request Payment',
                  ),
                  const PopupMenuDivider(),
                  _buildMenuItem(
                    context,
                    'remove',
                    Icons.delete_outline_rounded,
                    'Remove Contact',
                    isDestructive: true,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    BuildContext context,
    String value,
    IconData icon,
    String label, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : Theme.of(context).colorScheme.onSurface;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppDimens.sm),
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
