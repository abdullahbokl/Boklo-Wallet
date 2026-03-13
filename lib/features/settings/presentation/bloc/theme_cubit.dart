import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Manages the app's theme mode (light, dark, system).
///
/// Persists the user's preference using secure storage.
/// UI should react to state changes per Cubit/Bloc rules.
@lazySingleton
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._storage) : super(ThemeMode.system) {
    _loadTheme();
  }

  final FlutterSecureStorage _storage;
  static const _key = 'THEME_MODE';

  Future<void> _loadTheme() async {
    try {
      final stored = await _storage.read(key: _key);
      if (stored != null && !isClosed) {
        switch (stored) {
          case 'light':
            emit(ThemeMode.light);
          case 'dark':
            emit(ThemeMode.dark);
          default:
            emit(ThemeMode.system);
        }
      }
    } catch (e) {
      log('⚠️ ThemeCubit: Failed to load theme preference: $e');
      // Gracefully fall back to system theme
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    try {
      await _storage.write(key: _key, value: mode.name);
    } catch (e) {
      log('⚠️ ThemeCubit: Failed to persist theme preference: $e');
    }
  }

  Future<void> toggleTheme() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}
