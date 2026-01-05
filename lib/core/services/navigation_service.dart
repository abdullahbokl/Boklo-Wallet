import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<T?> push<T extends Object?>(String route) {
    return GoRouter.of(navigatorKey.currentContext!).push<T>(route);
  }

  void pushReplacement(String route) {
    GoRouter.of(navigatorKey.currentContext!).pushReplacement(route);
  }

  void pop<T extends Object?>([T? result]) {
    GoRouter.of(navigatorKey.currentContext!).pop(result);
  }
}
