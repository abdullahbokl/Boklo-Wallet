import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/notification_preferences/presentation/bloc/notification_preference_cubit.dart';
import 'package:boklo/features/notification_preferences/presentation/bloc/notification_preference_state.dart';
import 'package:boklo/features/notification_preferences/presentation/widgets/preference_item.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:boklo/shared/widgets/atoms/app_loading_indicator.dart';
import 'package:boklo/shared/widgets/molecules/app_page_scaffold.dart';
import 'package:boklo/shared/widgets/molecules/app_section_header.dart';
import 'package:boklo/shared/widgets/molecules/wallet_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<NotificationPreferenceCubit>();
        cubit.init();
        return cubit;
      },
      child: AppPageScaffold(
        title: 'Notification settings',
        child: BlocConsumer<NotificationPreferenceCubit,
            BaseState<NotificationPreferenceState>>(
          listener: (context, state) {
            state.whenOrNull(
              error: (e) => getIt<SnackbarService>().showError(e.message),
            );
          },
          builder: (context, state) {
            if (state.isLoading && state.data?.preferences == null) {
              return const AppLoadingIndicator();
            }

            final prefs = state.data?.preferences;
            if (prefs == null) {
              return WalletErrorView(
                onRetry: () =>
                    context.read<NotificationPreferenceCubit>().init(),
              );
            }

            return ListView(
              padding: const EdgeInsets.only(
                  top: AppDimens.md, bottom: AppDimens.xxl),
              children: [
                const AppSectionHeader(
                  title: 'Transfer alerts',
                  subtitle:
                      'Decide which money movement events should notify you.',
                ),
                const SizedBox(height: AppDimens.md),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      PreferenceItem(
                        title: 'Incoming transfers',
                        subtitle: 'Notify me when money arrives',
                        value: prefs.enableIncoming,
                        onChanged: (v) => context
                            .read<NotificationPreferenceCubit>()
                            .toggleIncoming(v),
                      ),
                      Divider(
                        height: 1,
                        indent: AppDimens.lg,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      PreferenceItem(
                        title: 'Outgoing transfers',
                        subtitle: 'Notify me when money is sent',
                        value: prefs.enableOutgoing,
                        onChanged: (v) => context
                            .read<NotificationPreferenceCubit>()
                            .toggleOutgoing(v),
                      ),
                    ],
                  ),
                ),
                if (state.data?.isUpdating ?? false) ...[
                  const SizedBox(height: AppDimens.md),
                  const LinearProgressIndicator(),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
