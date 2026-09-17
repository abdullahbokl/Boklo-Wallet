import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/notifications/presentation/bloc/unread_notifications_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Feeds the auth user into the app-wide unread counter.
class UnreadNotificationsObserver extends StatelessWidget {
  const UnreadNotificationsObserver({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, BaseState<User?>>(
      listener: (context, state) {
        context.read<UnreadNotificationsCubit>().observeUser(state.data?.id);
      },
      child: child,
    );
  }
}
