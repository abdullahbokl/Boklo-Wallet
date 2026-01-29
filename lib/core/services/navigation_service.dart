import 'dart:async';

import 'package:flutter/material.dart' hide showDialog;
import 'package:flutter/material.dart' as material show showDialog;
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<T?> push<T extends Object?>(String route, {Object? extra}) {
    return GoRouter.of(navigatorKey.currentContext!)
        .push<T>(route, extra: extra);
  }

  void pushReplacement(String route) {
    unawaited(GoRouter.of(navigatorKey.currentContext!).pushReplacement(route));
  }

  void go(String route) {
    GoRouter.of(navigatorKey.currentContext!).go(route);
  }

  void pop<T extends Object?>([T? result]) {
    GoRouter.of(navigatorKey.currentContext!).pop(result);
  }

  Future<T?> showDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return material.showDialog<T>(
      context: navigatorKey.currentContext!,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }
}
