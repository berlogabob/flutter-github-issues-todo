import 'package:flutter/material.dart';
import '../services/theme_prefs.dart';

/// Theme Provider - Manages app theme state
///
/// Handles:
/// - Theme mode selection (Dark/Light/System)
/// - Persistence of theme preferences
/// - Theme change notifications
class ThemeProvider extends ChangeNotifier {
  final ThemePrefs _themePrefs = ThemePrefs();

  AppThemeMode _themeMode = AppThemeMode.system;
  bool _isLoading = true;

  /// Get current theme mode
  AppThemeMode get themeMode => _themeMode;

  /// Check if currently loading theme preference
  bool get isLoading => _isLoading;

  /// Check if dark theme is active
  bool get isDarkMode => _themeMode == AppThemeMode.dark;

  /// Check if light theme is active
  bool get isLightMode => _themeMode == AppThemeMode.light;

  /// Check if system theme is active
  bool get isSystemMode => _themeMode == AppThemeMode.system;

  /// Initialize theme provider - load saved preference
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _themeMode = await _themePrefs.getThemeMode();
    } catch (_) {
      _themeMode = AppThemeMode.system;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Set theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      await _themePrefs.setThemeMode(mode);
    } catch (_) {
      // Ignore storage errors - UI already updated
    }
  }

  /// Toggle between dark and light mode
  Future<void> toggleTheme() async {
    if (_themeMode == AppThemeMode.dark) {
      await setThemeMode(AppThemeMode.light);
    } else {
      await setThemeMode(AppThemeMode.dark);
    }
  }

  /// Reset to system default
  Future<void> resetToSystem() async {
    await setThemeMode(AppThemeMode.system);
  }
}
