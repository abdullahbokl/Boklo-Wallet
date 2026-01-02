import 'dart:async';

import 'package:boklo/core/config/app_config.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:flutter/widgets.dart';

/// Centralized application initialization logic.
///
/// Handles:
/// - Widget binding initialization
/// - Dependency Injection setup
/// - Firebase initialization (placeholder)
class AppBootstrap {
  /// Initializes the application with the given [environment].
  static Future<void> bootstrap({
    required Environment environment,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Dependency Injection
    // The Environment string is passed to @Injectable
    await configureDependencies(environment.name);

    // Initialize Firebase (Placeholder)
    await _initFirebase();
  }

  static Future<void> _initFirebase() async {
    // TODO(Firebase): Initialize Firebase here when configurations are ready.
    // await Firebase.initializeApp();
  }
}
