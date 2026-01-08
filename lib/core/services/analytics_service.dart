import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AnalyticsService {
  // Toggle this or use environment variables to control tracking
  static const bool _enabled = kReleaseMode;

  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_enabled) {
      debugPrint('[Analytics] Event: $name, Params: $parameters');
      return;
    }
    // TODO(Analytics): Implement actual analytics provider
    // (e.g. Firebase, Mixpanel)
  }

  Future<void> logLogin({required String method}) async {
    await logEvent(
      name: 'login',
      parameters: {'method': method},
    );
  }

  Future<void> logTransferSuccess({
    required double amount,
    required String currency,
  }) async {
    await logEvent(
      name: 'transfer_success',
      parameters: {
        'amount': amount,
        'currency': currency,
      },
    );
  }

  Future<void> logTransferFailure({required String reason}) async {
    await logEvent(
      name: 'transfer_failure',
      parameters: {'reason': reason},
    );
  }
}
