import 'dart:async';

import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/config/app_feature_flags.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/auth/presentation/pages/login_page.dart';
import 'package:boklo/features/auth/presentation/pages/profile_setup_page.dart';
import 'package:boklo/features/auth/presentation/pages/register_page.dart';
import 'package:boklo/features/contacts/domain/entity/contact_entity.dart';
import 'package:boklo/features/contacts/presentation/page/contact_list_page.dart';
import 'package:boklo/features/ledger_debug/presentation/pages/ledger_debug_page.dart';
import 'package:boklo/features/notification_preferences/presentation/page/notification_settings_page.dart';
import 'package:boklo/features/notifications/presentation/pages/notifications_page.dart';
import 'package:boklo/features/payment_requests/presentation/pages/create_payment_request_page.dart';
import 'package:boklo/features/payment_requests/presentation/pages/payment_request_list_page.dart';
import 'package:boklo/features/profile/presentation/pages/profile_page.dart';
import 'package:boklo/features/transfers/presentation/pages/transfer_page.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/features/wallet/presentation/pages/transaction_detail_page.dart';
import 'package:boklo/features/wallet/presentation/pages/wallet_page.dart';
import 'package:boklo/shared/widgets/molecules/adaptive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AppRouter {
  AppRouter(this._navigationService, this._authCubit, this._featureFlags);

  final NavigationService _navigationService;
  final AuthCubit _authCubit;
  final AppFeatureFlags _featureFlags;

  late final Listenable _authListenable = _CubitListenable(_authCubit.stream);

  /// Routes reachable without an authenticated session.
  static const _publicPaths = {'/login', '/register'};

  /// Central auth guard: deep links to protected routes while logged out
  /// are redirected to /login, and a logged-in user never lands on /login.
  String? _redirect(BuildContext context, GoRouterState state) =>
      resolveRedirect(
        loggedIn: _authCubit.state.data != null,
        location: state.matchedLocation,
      );

  /// Pure redirect rule (unit-testable).
  static String? resolveRedirect({
    required bool loggedIn,
    required String location,
  }) {
    final isPublic = _publicPaths.contains(location);

    if (!loggedIn && !isPublic) return '/login';
    if (loggedIn && location == '/login') return '/wallet';
    return null;
  }

  late final GoRouter router = GoRouter(
    navigatorKey: _navigationService.navigatorKey,
    initialLocation: '/login',
    refreshListenable: _authListenable,
    redirect: _redirect,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupPage(),
      ),
      GoRoute(
        path: '/transaction-detail',
        builder: (context, state) => TransactionDetailPage.fromExtra(
          state.extra! as Map<String, dynamic>,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdaptiveScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wallet',
                builder: (context, state) => BlocProvider(
                  create: (context) {
                    final cubit = getIt<WalletCubit>();
                    unawaited(cubit.loadWallet());
                    return cubit;
                  },
                  child: const WalletPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transfer',
                builder: (context, state) {
                  // Extra may be a ContactEntity (contacts page), a plain
                  // recipient identifier string (retry flow), or absent.
                  final extra = state.extra;
                  final prefilled = switch (extra) {
                    final ContactEntity contact => contact.email,
                    final String recipient => recipient,
                    _ => null,
                  };
                  return TransferPage(prefilledRecipient: prefilled);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/payment-requests',
                builder: (context, state) => const PaymentRequestListPage(),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (context, state) {
                      // Extract contact UID if passed from contacts page
                      final contact = state.extra as ContactEntity?;
                      return CreatePaymentRequestPage(
                        prefilledPayerId: contact?.uid,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/contacts',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return ContactListPage(
                    isPickMode: (extra?['pickMode'] as bool?) ?? false,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      // --- Pushed detail routes (render above the shell) ---
      // Debug-only ledger view, gated behind a feature flag so it can
      // never be reached in production builds.
      if (_featureFlags.enableLedgerDebug)
        GoRoute(
          path: '/ledger',
          builder: (context, state) => const LedgerDebugPage(),
        ),
      GoRoute(
        path: '/notification-settings',
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
  );
}

/// Bridges a Cubit's state stream to the [Listenable] interface that
/// GoRouter's refreshListenable expects (bloc 9 cubits are pure Dart).
class _CubitListenable extends ChangeNotifier {
  _CubitListenable(Stream<dynamic> stream) {
    _subscription = stream.listen(
      (_) => notifyListeners(),
      onError: (_) => notifyListeners(),
      onDone: notifyListeners,
    );
  }

  StreamSubscription<dynamic>? _subscription;

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
