import 'dart:async';

import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/features/auth/presentation/pages/login_page.dart';
import 'package:boklo/features/auth/presentation/pages/register_page.dart';
import 'package:boklo/features/ledger_debug/presentation/pages/ledger_debug_page.dart';
import 'package:boklo/features/transfers/presentation/pages/transfer_page.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/features/wallet/presentation/pages/wallet_page.dart';
import 'package:boklo/features/payment_requests/presentation/pages/payment_request_list_page.dart';
import 'package:boklo/features/payment_requests/presentation/pages/create_payment_request_page.dart';
import 'package:boklo/features/contacts/presentation/page/contact_list_page.dart';
import 'package:boklo/features/notification_preferences/presentation/page/notification_settings_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AppRouter {
  AppRouter(this._navigationService);

  final NavigationService _navigationService;

  String initialLocation = '/login';

  late final GoRouter router = GoRouter(
    navigatorKey: _navigationService.navigatorKey,
    initialLocation: initialLocation,
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
      GoRoute(
        path: '/transfer',
        builder: (context, state) => const TransferPage(),
      ),
      GoRoute(
        path: '/ledger-debug',
        builder: (context, state) => const LedgerDebugPage(),
      ),
      GoRoute(
        path: '/payment-requests',
        builder: (context, state) => const PaymentRequestListPage(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreatePaymentRequestPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/contacts',
        builder: (context, state) => const ContactListPage(),
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (context, state) => const NotificationSettingsPage(),
      ),
    ],
  );
}
