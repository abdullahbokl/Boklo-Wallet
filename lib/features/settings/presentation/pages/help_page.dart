import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/widgets/molecules/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Help & support: FAQ accordion, support contact, and pointers to the
/// in-app dispute flow.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final faqs = <(String, String)>[
      (l10n.helpFaqTitle, l10n.helpFaqTransfers),
      (l10n.helpFaqLimitsTitle, l10n.helpFaqLimits),
      (l10n.helpFaqVerification, l10n.helpFaqVerification),
    ];

    return AppPageScaffold(
      title: l10n.helpTitle,
      child: ListView(
        padding: const EdgeInsets.all(AppDimens.lg),
        children: [
          Text(
            l10n.helpFaqTitle,
            style: AppTypography.subtitle,
          ),
          const SizedBox(height: AppDimens.md),
          ...faqs.map(
            (faq) => Card(
              margin: const EdgeInsets.only(bottom: AppDimens.sm),
              elevation: 0,
              color: scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.lg,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(
                  AppDimens.lg,
                  0,
                  AppDimens.lg,
                  AppDimens.lg,
                ),
                shape: const Border(),
                title: Text(faq.$1, style: AppTypography.bodyLarge),
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      faq.$2,
                      style: AppTypography.bodyMedium.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimens.xl),
          Text(
            l10n.helpContact,
            style: AppTypography.subtitle,
          ),
          const SizedBox(height: AppDimens.md),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: ListTile(
              leading: const Icon(Icons.mail_outline_rounded),
              title: Text(l10n.helpContactEmail),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: () => unawaitedLaunchMail(l10n.helpContactEmail),
            ),
          ),
          const SizedBox(height: AppDimens.lg),
          Text(
            l10n.helpDisputeHint,
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> unawaitedLaunchMail(String email) async {
  final uri = Uri(scheme: 'mailto', path: email);
  await launchUrl(uri);
}
