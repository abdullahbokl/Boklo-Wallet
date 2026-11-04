import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Manages the app's display language.
///
/// [Locale] of `null` means "follow the system locale". A concrete locale
/// (en/ar) overrides it. Persists the choice via secure storage.
@lazySingleton
class LocaleCubit extends Cubit<Locale?> {
  LocaleCubit(this._storage) : super(null) {
    unawaited(_loadLocale());
  }

  final FlutterSecureStorage _storage;
  static const _key = 'APP_LOCALE';

  Future<void> _loadLocale() async {
    try {
      final stored = await _storage.read(key: _key);
      if (stored == null || isClosed) return;
      emit(switch (stored) {
        'en' => const Locale('en'),
        'ar' => const Locale('ar'),
        _ => null,
      });
    } on Object catch (e) {
      log('⚠️ LocaleCubit: Failed to load locale preference: $e');
    }
  }

  /// [languageCode] of `null` restores system-locale following.
  Future<void> setLanguageCode(String? languageCode) async {
    emit(languageCode == null ? null : Locale(languageCode));
    try {
      if (languageCode == null) {
        await _storage.delete(key: _key);
      } else {
        await _storage.write(key: _key, value: languageCode);
      }
    } on Object catch (e) {
      log('⚠️ LocaleCubit: Failed to persist locale preference: $e');
    }
  }
}
