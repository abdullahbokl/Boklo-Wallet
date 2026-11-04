import 'dart:async';

import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/settings/domain/entities/device_session.dart';
import 'package:boklo/features/settings/presentation/bloc/devices_cubit.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:boklo/shared/widgets/atoms/app_loading_indicator.dart';
import 'package:boklo/shared/widgets/molecules/app_page_scaffold.dart';
import 'package:boklo/shared/widgets/molecules/wallet_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Lists registered devices (FCM push sessions) and offers
/// "sign out everywhere" (revoke refresh tokens server-side).
class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: context.l10n.devicesTitle,
      child: BlocProvider(
        create: (_) => getIt<DevicesCubit>()..unawaitedLoad(),
        child: const _DevicesBody(),
      ),
    );
  }
}

extension on DevicesCubit {
  void unawaitedLoad() {
    unawaited(load());
  }
}

class _DevicesBody extends StatelessWidget {
  const _DevicesBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DevicesCubit, BaseState<List<DeviceSession>>>(
      builder: (context, state) {
        if (state.isLoading) {
          return const AppLoadingIndicator();
        }
        final error = state.error;
        if (error != null) {
          return WalletErrorView(
            title: error.message,
            onRetry: () => context.read<DevicesCubit>().load(),
          );
        }
        final devices = state.data ?? const <DeviceSession>[];

        return ListView(
          padding: const EdgeInsets.all(AppDimens.lg),
          children: [
            Text(
              context.l10n.devicesSubtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            if (devices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimens.xxl),
                child: Center(
                  child: Text(context.l10n.devicesEmpty),
                ),
              )
            else
              ...devices.map(
                (device) => Card(
                  margin: const EdgeInsets.only(bottom: AppDimens.sm),
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      device.isCurrentDevice
                          ? Icons.smartphone_rounded
                          : Icons.devices_other_rounded,
                    ),
                    title: Text(
                      device.isCurrentDevice
                          ? context.l10n.devicesThisDevice
                          : context.l10n.devicesOtherLabel(device.platform),
                    ),
                    subtitle: device.createdAt != null
                        ? Text(
                            DateFormat.yMMMd().add_jm().format(
                              device.createdAt!,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            const SizedBox(height: AppDimens.xl),
            AppButton(
              text: context.l10n.signOutEverywhere,
              variant: AppButtonVariant.destructive,
              onPressed: () => unawaited(_confirmRevoke(context)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmRevoke(BuildContext context) async {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final scaffold = ScaffoldMessenger.of(context);
    final cubit = context.read<DevicesCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signOutEverywhere),
        content: Text(l10n.signOutEverywhereBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.signOutEverywhere),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final revoked = await cubit.revokeAll();
    if (!revoked) return;

    scaffold.showSnackBar(
      SnackBar(content: Text(l10n.sessionsRevoked)),
    );
    // Revoke invalidates this session too; sign out locally.
    await getIt<AuthCubit>().logout();
    navigator.pop();
  }
}
