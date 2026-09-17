import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Firebase Analytics implementation.
///
/// Events are sent in release builds; debug builds print instead so local
/// runs do not pollute production analytics. No PII (emails, usernames,
/// identifiers) is ever logged — only event names and coarse parameters.
@lazySingleton
class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  bool get _enabled => kReleaseMode;

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_enabled) {
      debugPrint('[Analytics] Event: $name, Params: $parameters');
      return;
    }
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } on Object catch (e) {
      debugPrint('[Analytics] Failed to log "$name": $e');
    }
  }

  Future<void> logLogin({required String method}) async {
    await logEvent(
      name: 'login',
      parameters: {'method': method},
    );
  }

  Future<void> logSignUp({required String method}) async {
    await logEvent(name: 'sign_up', parameters: {'method': method});
  }

  Future<void> logTransferSuccess({
    required int amount,
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

  Future<void> logTransferInitiated({
    required int amount,
    required String currency,
  }) async {
    await logEvent(
      name: 'transfer_initiated',
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

  Future<void> logPaymentRequestCreated() async {
    await logEvent(name: 'payment_request_created');
  }

  Future<void> logPaymentRequestAccepted() async {
    await logEvent(name: 'payment_request_accepted');
  }

  Future<void> logScreenView({required String screenName}) async {
    if (!_enabled) return;
    try {
      await _analytics.logScreenView(screenName: screenName);
    } on Object catch (e) {
      debugPrint('[Analytics] Failed to log screen "$screenName": $e');
    }
  }
}
