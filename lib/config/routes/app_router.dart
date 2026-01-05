import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/features/auth/presentation/pages/login_page.dart';
import 'package:boklo/features/auth/presentation/pages/register_page.dart';
import 'package:boklo/features/transfers/presentation/pages/transfer_page.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/features/wallet/presentation/pages/wallet_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AppRouter {
  AppRouter(this._navigationService);

  final NavigationService _navigationService;

  late final GoRouter router = GoRouter(
    navigatorKey: _navigationService.navigatorKey,
    initialLocation: '/login',
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
          create: (context) => getIt<WalletCubit>()..loadWallet(),
          child: const WalletPage(),
        ),
      ),
      GoRoute(
        path: '/transfer',
        builder: (context, state) => const TransferPage(),
      ),
    ],
  );
}
