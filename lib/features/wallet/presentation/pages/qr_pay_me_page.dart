import 'dart:async';

import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/wallet/domain/services/pay_me_payload.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:boklo/l10n/generated/app_localizations.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/widgets/molecules/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Shows the user's personal pay-me QR code and lets them share their
/// handle. Scanning the code with Boklo prefills a transfer to them.
class QrPayMePage extends StatelessWidget {
  const QrPayMePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: context.l10n.qrTitle,
      child: BlocBuilder<WalletCubit, BaseState<WalletState>>(
        builder: (context, state) {
          final wallet = state.data?.wallet;
          final handle = wallet?.username ?? wallet?.alias;
          final scheme = Theme.of(context).colorScheme;

          if (handle == null || handle.isEmpty) {
            return Center(
              child: Text(
                context.l10n.qrNoHandle,
                style: AppTypography.bodyMedium.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          final payload = PayMePayload.encode(handle);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimens.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  ),
                  child: QrImageView(data: payload, size: 240),
                ),
                const SizedBox(height: AppDimens.xl),
                Text(
                  context.l10n.qrYourHandle,
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppDimens.xs4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('@$handle', style: AppTypography.title),
                    IconButton(
                      tooltip: context.l10n.copiedToClipboard,
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () {
                        unawaited(
                          Clipboard.setData(ClipboardData(text: handle)),
                        );
                        getIt<SnackbarService>().showSuccess(
                          context.l10n.copiedToClipboard,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.lg),
                Text(
                  context.l10n.qrSubtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.xl),
                FilledButton.icon(
                  onPressed: () =>
                      unawaited(_share(context.l10n, payload, handle)),
                  icon: const Icon(Icons.share_rounded),
                  label: Text(context.l10n.qrShare),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _share(
    AppLocalizations l10n,
    String payload,
    String handle,
  ) async {
    await SharePlus.instance.share(
      ShareParams(text: l10n.qrShareText(handle), title: 'Boklo'),
    );
  }
}
