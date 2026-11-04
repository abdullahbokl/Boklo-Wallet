import 'dart:async';

import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/contacts/domain/entity/contact_entity.dart';
import 'package:boklo/features/contacts/domain/repo/contact_repository.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/widgets/atoms/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;

/// Horizontal quick-pick row of favorite contacts on the send screen.
///
/// Hidden entirely when the user has no favorites. Tapping a favorite fills
/// the recipient field via [onSelected].
class TransferFavoritesRow extends StatefulWidget {
  const TransferFavoritesRow({required this.onSelected, super.key});

  final ValueChanged<ContactEntity> onSelected;

  @override
  State<TransferFavoritesRow> createState() => _TransferFavoritesRowState();
}

class _TransferFavoritesRowState extends State<TransferFavoritesRow> {
  late final StreamSubscription<Either<Failure, List<ContactEntity>>> _sub;
  List<ContactEntity> _favorites = const [];

  @override
  void initState() {
    super.initState();
    _sub = getIt<ContactRepository>().watchContacts().listen((result) {
      if (!mounted) return;
      result.fold(
        (_) {},
        (contacts) {
          setState(() {
            _favorites = contacts.where((c) => c.isFavorite).toList();
          });
        },
      );
    });
  }

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_favorites.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.favoritesSection,
          style: AppTypography.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _favorites.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppDimens.md),
            itemBuilder: (context, index) {
              final contact = _favorites[index];
              return InkWell(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                onTap: () => widget.onSelected(contact),
                child: SizedBox(
                  width: 68,
                  child: Column(
                    children: [
                      AppAvatar(
                        photoUrl: contact.photoUrl,
                        name: contact.displayName,
                        size: 48,
                      ),
                      const SizedBox(height: AppDimens.xs4),
                      Text(
                        contact.displayName,
                        style: AppTypography.label.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
