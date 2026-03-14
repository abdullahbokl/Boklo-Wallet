/// Configuration for a single page's performance test.
///
/// Each page to be benchmarked gets a [PageTestConfig] that describes
/// how to navigate to it and how to stress-test it.
class PageTestConfig {
  const PageTestConfig({
    required this.pageName,
    required this.routePath,
    this.routeExtra,
    this.hasScrollableContent = true,
    this.scrollIterations = 5,
    this.settleTimeout = const Duration(seconds: 10),
    this.requiresAuth = false,
  });

  /// Human-readable name (e.g., "LoginPage"). Used as the key in JSON output.
  final String pageName;

  /// The GoRouter path to navigate to (e.g., "/login", "/wallet").
  final String routePath;

  /// Optional `extra` parameter passed to `GoRouter.go()`.
  /// Use this for pages that require route extras (e.g., ContactEntity).
  final Object? routeExtra;

  /// Whether the page has scrollable content worth stress-testing.
  /// Set to `false` for simple forms like login/register.
  final bool hasScrollableContent;

  /// Number of fling iterations during stress scroll.
  final int scrollIterations;

  /// Maximum time to wait for animations to settle after navigation.
  final Duration settleTimeout;

  /// Whether to simulate a logged-in user before navigating.
  final bool requiresAuth;

  @override
  String toString() => 'PageTestConfig($pageName, route=$routePath, auth=$requiresAuth)';
}
