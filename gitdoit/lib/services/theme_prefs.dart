import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Theme preference options
enum AppThemeMode {
  /// Follow system settings
  system,

  /// Always use dark theme
  dark,

  /// Always use light theme
  light,
}

/// Theme preferences service
///
/// Handles persistence of theme preferences using secure storage.
class ThemePrefs {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _themeKey = 'theme_mode';

  /// Get current theme mode
  Future<AppThemeMode> getThemeMode() async {
    try {
      final value = await _storage.read(key: _themeKey);
      if (value == null) {
        return AppThemeMode.system;
      }
      return AppThemeMode.values.firstWhere(
        (mode) => mode.name == value,
        orElse: () => AppThemeMode.system,
      );
    } catch (_) {
      return AppThemeMode.system;
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    try {
      await _storage.write(key: _themeKey, value: mode.name);
    } catch (_) {
      // Ignore storage errors
    }
  }

  /// Check if theme is dark
  Future<bool> isDarkMode() async {
    final mode = await getThemeMode();
    return mode == AppThemeMode.dark;
  }

  /// Check if theme follows system
  Future<bool> isSystemMode() async {
    final mode = await getThemeMode();
    return mode == AppThemeMode.system;
  }

  /// Clear theme preference
  Future<void> clearThemeMode() async {
    try {
      await _storage.delete(key: _themeKey);
    } catch (_) {
      // Ignore storage errors
    }
  }
}
