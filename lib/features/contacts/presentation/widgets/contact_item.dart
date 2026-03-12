import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/features/contacts/domain/entity/contact_entity.dart';
import 'package:boklo/shared/widgets/atoms/app_avatar.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:flutter/material.dart';

class ContactItem extends StatelessWidget {
  const ContactItem({
    required this.contact,
    super.key,
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
    final scheme = Theme.of(context).colorScheme;

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
                    style: AppTypography.subtitle.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppDimens.xs4),
                  Text(
                    contact.email,
                    style: AppTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!isPickMode)
              _ContactActionMenu(
                onSendMoney: onSendMoney,
                onRequestMoney: onRequestMoney,
                onRemove: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactActionMenu extends StatelessWidget {
  const _ContactActionMenu({
    this.onSendMoney,
    this.onRequestMoney,
    this.onRemove,
  });

  final VoidCallback? onSendMoney;
  final VoidCallback? onRequestMoney;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (value) {
        if (value == 'send') onSendMoney?.call();
        if (value == 'request') onRequestMoney?.call();
        if (value == 'remove') onRemove?.call();
      },
      itemBuilder: (context) => [
        _buildMenuItem(context, 'send', Icons.send_rounded, 'Send money'),
        _buildMenuItem(
          context,
          'request',
          Icons.request_page_rounded,
          'Request payment',
        ),
        const PopupMenuDivider(),
        _buildMenuItem(
          context,
          'remove',
          Icons.delete_outline_rounded,
          'Remove contact',
          isDestructive: true,
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    BuildContext context,
    String value,
    IconData icon,
    String label, {
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: AppDimens.iconMd, color: color),
          const SizedBox(width: AppDimens.sm),
          Text(label, style: AppTypography.bodyMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}
