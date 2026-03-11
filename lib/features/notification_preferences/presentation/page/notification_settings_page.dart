import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/notification_preferences/presentation/bloc/notification_preference_cubit.dart';
import 'package:boklo/features/notification_preferences/presentation/bloc/notification_preference_state.dart';
import 'package:boklo/shared/responsive/responsive_constraint.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:boklo/shared/widgets/molecules/app_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (context) {
        final cubit = getIt<NotificationPreferenceCubit>();
        cubit.init();
        return cubit;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scheme.primary.withValues(alpha: 0.1),
                scheme.surface,
                scheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: ResponsiveConstraint(
              child: BlocConsumer<NotificationPreferenceCubit,
                  BaseState<NotificationPreferenceState>>(
                listener: (context, state) {
                  state.whenOrNull(error: (e) {
                    getIt<SnackbarService>().showError(e.message);
                  });
                },
                builder: (context, state) {
                  if (state.isLoading && state.data?.preferences == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final prefs = state.data?.preferences;
                  if (prefs == null) {
                    return const Center(child: Text('Failed to load settings'));
                  }

                  return ListView(
                    padding: const EdgeInsets.all(AppDimens.lg),
                    children: [
                      const AppSectionHeader(title: 'Transaction Alerts'),
                      const SizedBox(height: AppDimens.md),
                      AppCard(
                        useGlass: true,
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _PreferenceItem(
                              title: 'Incoming Transfers',
                              subtitle: 'Receive alerts when money arrives',
                              value: prefs.enableIncoming,
                              onChanged: (v) => context
                                  .read<NotificationPreferenceCubit>()
                                  .toggleIncoming(v),
                            ),
                            Divider(
                                height: 1,
                                indent: AppDimens.lg,
                                color: scheme.outlineVariant),
                            _PreferenceItem(
                              title: 'Outgoing Transfers',
                              subtitle: 'Receive alerts when money is sent',
                              value: prefs.enableOutgoing,
                              onChanged: (v) => context
                                  .read<NotificationPreferenceCubit>()
                                  .toggleOutgoing(v),
                            ),
                          ],
                        ),
                      ),
                      if (state.data?.isUpdating ?? false)
                        const Padding(
                          padding: EdgeInsets.only(top: AppDimens.lg),
                          child: Center(child: LinearProgressIndicator()),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreferenceItem extends StatelessWidget {
  const _PreferenceItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.lg,
        vertical: AppDimens.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: scheme.primary,
          ),
        ],
      ),
    );
  }
}
