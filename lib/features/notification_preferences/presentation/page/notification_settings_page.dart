import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/features/notification_preferences/presentation/bloc/notification_preference_cubit.dart';
import 'package:boklo/features/notification_preferences/presentation/bloc/notification_preference_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:boklo/core/services/snackbar_service.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = getIt<NotificationPreferenceCubit>();
        cubit.init();
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: BlocConsumer<NotificationPreferenceCubit,
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
            final isUpdating = state.data?.isUpdating == true;

            if (prefs == null) {
              return const Center(child: Text('Failed to load settings'));
            }

            return ListView(
              children: [
                SwitchListTile(
                  title: const Text('Incoming Transfers'),
                  subtitle: const Text('Receive alerts when money arrives'),
                  value: prefs.enableIncoming,
                  onChanged: isUpdating
                      ? null
                      : (value) {
                          context
                              .read<NotificationPreferenceCubit>()
                              .toggleIncoming(value);
                        },
                ),
                SwitchListTile(
                  title: const Text('Outgoing Transfers'),
                  subtitle: const Text('Receive alerts when money is sent'),
                  value: prefs.enableOutgoing,
                  onChanged: isUpdating
                      ? null
                      : (value) {
                          context
                              .read<NotificationPreferenceCubit>()
                              .toggleOutgoing(value);
                        },
                ),
                if (isUpdating)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: LinearProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
