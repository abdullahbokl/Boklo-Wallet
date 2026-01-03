import 'package:boklo/features/auth/presentation/pages/login_page.dart';
import 'package:boklo/features/auth/presentation/pages/register_page.dart';
import 'package:boklo/features/wallet/presentation/pages/wallet_page.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AppRouter {
  final GoRouter router = GoRouter(
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
        builder: (context, state) => const WalletPage(),
      ),
    ],
  );
}
