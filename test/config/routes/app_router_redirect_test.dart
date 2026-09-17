import 'package:boklo/config/routes/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRouter.resolveRedirect', () {
    test('redirects logged-out users from protected routes to /login', () {
      for (final location in [
        '/wallet',
        '/transfer',
        '/profile',
        '/contacts',
        '/payment-requests',
        '/notifications',
      ]) {
        expect(
          AppRouter.resolveRedirect(loggedIn: false, location: location),
          '/login',
          reason: 'location $location must be protected',
        );
      }
    });

    test('allows logged-out users on public routes', () {
      expect(
        AppRouter.resolveRedirect(loggedIn: false, location: '/login'),
        isNull,
      );
      expect(
        AppRouter.resolveRedirect(loggedIn: false, location: '/register'),
        isNull,
      );
    });

    test('redirects logged-in users away from /login', () {
      expect(
        AppRouter.resolveRedirect(loggedIn: true, location: '/login'),
        '/wallet',
      );
    });

    test('leaves logged-in users on protected routes', () {
      expect(
        AppRouter.resolveRedirect(loggedIn: true, location: '/wallet'),
        isNull,
      );
      expect(
        AppRouter.resolveRedirect(
          loggedIn: true,
          location: '/payment-requests/create',
        ),
        isNull,
      );
    });
  });
}
