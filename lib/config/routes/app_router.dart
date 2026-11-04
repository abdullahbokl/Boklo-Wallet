import 'dart:async';

import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/config/app_feature_flags.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/error/failures.dart';
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
import 'package:boklo/features/settings/presentation/pages/help_page.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/domain/repositories/transfer_repository.dart';
import 'package:boklo/features/transfers/presentation/pages/scan_recipient_page.dart';
import 'package:boklo/features/transfers/presentation/pages/transfer_page.dart';
import 'package:boklo/features/transfers/presentation/pages/transfer_receipt_page.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/features/wallet/presentation/pages/qr_pay_me_page.dart';
import 'package:boklo/features/wallet/presentation/pages/transaction_detail_page.dart';
import 'package:boklo/features/wallet/presentation/pages/wallet_page.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/widgets/molecules/adaptive_scaffold.dart';
import 'package:boklo/shared/widgets/molecules/app_page_scaffold.dart';
import 'package:boklo/shared/widgets/molecules/wallet_error_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;
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
        path: '/transfer-receipt',
        builder: (context, state) => TransferReceiptPage(
          transfer: state.extra! as TransferEntity,
        ),
      ),
      GoRoute(
        path: '/transaction-detail',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is String) {
            // Deep-linked from a notification: load the transfer by id.
            return _TransferDetailLoader(transferId: extra);
          }
          return TransactionDetailPage.fromExtra(
            extra! as Map<String, dynamic>,
          );
        },
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
        path: '/help',
        builder: (context, state) => const HelpPage(),
      ),
      GoRoute(
        path: '/qr',
        builder: (context, state) => const QrPayMePage(),
      ),
      GoRoute(
        path: '/scan-recipient',
        builder: (context, state) => const ScanRecipientPage(),
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

/// Loads a transfer by id (party-readable per Firestore rules) and renders
/// its detail page; used when deep-linked from a push notification.
class _TransferDetailLoader extends StatefulWidget {
  const _TransferDetailLoader({required this.transferId});

  final String transferId;

  @override
  State<_TransferDetailLoader> createState() => _TransferDetailLoaderState();
}

class _TransferDetailLoaderState extends State<_TransferDetailLoader> {
  late final Future<Either<Failure, TransferEntity?>> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<TransferRepository>()
        .observeTransfer(widget.transferId)
        .firstWhere((either) => either.isRight());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<Failure, TransferEntity?>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final result = snapshot.data;
        if (result == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return result.fold(
          (failure) => AppPageScaffold(
            title: context.l10n.transactionDetailTitle,
            child: WalletErrorView(
              title: failure.message,
              onRetry: () => getIt<NavigationService>().go('/wallet'),
            ),
          ),
          (transfer) {
            if (transfer == null) {
              return AppPageScaffold(
                title: context.l10n.transactionDetailTitle,
                child: WalletErrorView(
                  title: context.l10n.notFound,
                  onRetry: () => getIt<NavigationService>().go('/wallet'),
                ),
              );
            }
            final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
            return TransactionDetailPage(
              transaction: TransactionEntity(
                id: transfer.id,
                amount: transfer.amount,
                type: transfer.fromWalletId == uid
                    ? TransactionType.debit
                    : TransactionType.credit,
                timestamp: transfer.createdAt,
                status: switch (transfer.status) {
                  TransferStatus.pending => TransactionStatus.pending,
                  TransferStatus.completed => TransactionStatus.completed,
                  TransferStatus.failed => TransactionStatus.failed,
                },
                counterpartyId: transfer.fromWalletId == uid
                    ? transfer.toWalletId
                    : transfer.fromWalletId,
                description: transfer.failureReason,
              ),
              currency: transfer.currency,
              walletId: uid,
            );
          },
        );
      },
    );
  }
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
