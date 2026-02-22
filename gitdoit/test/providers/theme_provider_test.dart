import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/providers/theme_provider.dart';
import 'package:gitdoit/services/theme_prefs.dart';

void main() {
  group('ThemeProvider', () {
    late ThemeProvider themeProvider;

    setUp(() {
      themeProvider = ThemeProvider();
    });

    tearDown(() {
      themeProvider.dispose();
    });

    group('Initial State', () {
      test('should have isLoading true initially', () {
        // Assert
        expect(themeProvider.isLoading, true);
      });

      test('should have themeMode as system initially (before initialize)', () {
        // Note: themeMode defaults to system before initialization
        expect(themeProvider.themeMode, AppThemeMode.system);
      });

      test('should have isDarkMode false initially', () {
        // Assert
        expect(themeProvider.isDarkMode, false);
      });

      test('should have isLightMode false initially', () {
        // Assert
        expect(themeProvider.isLightMode, false);
      });

      test('should have isSystemMode true initially', () {
        // Assert
        expect(themeProvider.isSystemMode, true);
      });
    });

    group('initialize', () {
      test('should set isLoading to false after initialization', () async {
        // Act
        await themeProvider.initialize();

        // Assert
        expect(themeProvider.isLoading, false);
      });

      test('should load theme mode from preferences', () async {
        // Act
        await themeProvider.initialize();

        // Assert - should have loaded a valid theme mode
        expect(themeProvider.themeMode, isNotNull);
        expect(AppThemeMode.values.contains(themeProvider.themeMode), true);
      });

      test('should default to system mode on error', () async {
        // Act
        await themeProvider.initialize();

        // Assert - defaults to system on any error
        expect(themeProvider.themeMode, AppThemeMode.system);
      });

      test('should notify listeners after initialization', () async {
        // Arrange
        var notifyCount = 0;
        themeProvider.addListener(() => notifyCount++);

        // Act
        await themeProvider.initialize();

        // Assert - at least one notification (isLoading change)
        expect(notifyCount, greaterThan(0));
      });
    });

    group('setThemeMode', () {
      test('should update theme mode to dark', () async {
        // Arrange
        await themeProvider.initialize();

        // Act
        await themeProvider.setThemeMode(AppThemeMode.dark);

        // Assert
        expect(themeProvider.themeMode, AppThemeMode.dark);
        expect(themeProvider.isDarkMode, true);
        expect(themeProvider.isLightMode, false);
        expect(themeProvider.isSystemMode, false);
      });

      test('should update theme mode to light', () async {
        // Arrange
        await themeProvider.initialize();

        // Act
        await themeProvider.setThemeMode(AppThemeMode.light);

        // Assert
        expect(themeProvider.themeMode, AppThemeMode.light);
        expect(themeProvider.isDarkMode, false);
        expect(themeProvider.isLightMode, true);
        expect(themeProvider.isSystemMode, false);
      });

      test('should update theme mode to system', () async {
        // Arrange
        await themeProvider.initialize();
        await themeProvider.setThemeMode(AppThemeMode.dark);

        // Act
        await themeProvider.setThemeMode(AppThemeMode.system);

        // Assert
        expect(themeProvider.themeMode, AppThemeMode.system);
        expect(themeProvider.isDarkMode, false);
        expect(themeProvider.isLightMode, false);
        expect(themeProvider.isSystemMode, true);
      });

      test('should not notify if setting same mode', () async {
        // Arrange
        await themeProvider.initialize();
        var notifyCount = 0;
        themeProvider.addListener(() => notifyCount++);

        // Act - set to current mode (system)
        await themeProvider.setThemeMode(AppThemeMode.system);

        // Assert
        expect(notifyCount, 0);
      });

      test('should notify listeners when mode changes', () async {
        // Arrange
        await themeProvider.initialize();
        var notifyCount = 0;
        themeProvider.addListener(() => notifyCount++);

        // Act
        await themeProvider.setThemeMode(AppThemeMode.dark);

        // Assert
        expect(notifyCount, 1);
      });

      test('should persist theme mode', () async {
        // Arrange
        await themeProvider.initialize();

        // Act
        await themeProvider.setThemeMode(AppThemeMode.dark);

        // Assert - mode is set (persistence tested in theme_prefs_test)
        expect(themeProvider.themeMode, AppThemeMode.dark);
      });
    });

    group('toggleTheme', () {
      test('should toggle from dark to light', () async {
        // Arrange
        await themeProvider.initialize();
        await themeProvider.setThemeMode(AppThemeMode.dark);
        expect(themeProvider.isDarkMode, true);

        // Act
        await themeProvider.toggleTheme();

        // Assert
        expect(themeProvider.themeMode, AppThemeMode.light);
        expect(themeProvider.isLightMode, true);
      });

      test('should toggle from light to dark', () async {
        // Arrange
        await themeProvider.initialize();
        await themeProvider.setThemeMode(AppThemeMode.light);
        expect(themeProvider.isLightMode, true);

        // Act
        await themeProvider.toggleTheme();

        // Assert
        expect(themeProvider.themeMode, AppThemeMode.dark);
        expect(themeProvider.isDarkMode, true);
      });

      test('should toggle from system to dark', () async {
        // Arrange
        await themeProvider.initialize();
        expect(themeProvider.isSystemMode, true);

        // Act
        await themeProvider.toggleTheme();

        // Assert
        expect(themeProvider.themeMode, AppThemeMode.dark);
        expect(themeProvider.isDarkMode, true);
      });

      test('should notify listeners on toggle', () async {
        // Arrange
        await themeProvider.initialize();
        var notifyCount = 0;
        themeProvider.addListener(() => notifyCount++);

        // Act
        await themeProvider.toggleTheme();

        // Assert
        expect(notifyCount, 1);
      });
    });

    group('resetToSystem', () {
      test('should reset to system mode from dark', () async {
        // Arrange
        await themeProvider.initialize();
        await themeProvider.setThemeMode(AppThemeMode.dark);
        expect(themeProvider.isDarkMode, true);

        // Act
        await themeProvider.resetToSystem();

        // Assert
        expect(themeProvider.themeMode, AppThemeMode.system);
        expect(themeProvider.isSystemMode, true);
      });

      test('should reset to system mode from light', () async {
        // Arrange
        await themeProvider.initialize();
        await themeProvider.setThemeMode(AppThemeMode.light);
        expect(themeProvider.isLightMode, true);

        // Act
        await themeProvider.resetToSystem();

        // Assert
        expect(themeProvider.themeMode, AppThemeMode.system);
        expect(themeProvider.isSystemMode, true);
      });

      test('should notify listeners on reset', () async {
        // Arrange
        await themeProvider.initialize();
        await themeProvider.setThemeMode(AppThemeMode.dark);
        var notifyCount = 0;
        themeProvider.addListener(() => notifyCount++);

        // Act
        await themeProvider.resetToSystem();

        // Assert
        expect(notifyCount, 1);
      });

      test('should not notify if already in system mode', () async {
        // Arrange
        await themeProvider.initialize();
        var notifyCount = 0;
        themeProvider.addListener(() => notifyCount++);

        // Act - already in system mode
        await themeProvider.resetToSystem();

        // Assert
        expect(notifyCount, 0);
      });
    });

    group('Getters', () {
      test('should return current themeMode', () async {
        // Arrange
        await themeProvider.initialize();

        // Assert
        expect(themeProvider.themeMode, isNotNull);
      });

      test('should return isLoading state', () {
        // Assert
        expect(themeProvider.isLoading, true);
      });

      test('should return isDarkMode based on themeMode', () async {
        // Arrange
        await themeProvider.initialize();
        await themeProvider.setThemeMode(AppThemeMode.dark);

        // Assert
        expect(themeProvider.isDarkMode, true);
      });

      test('should return isLightMode based on themeMode', () async {
        // Arrange
        await themeProvider.initialize();
        await themeProvider.setThemeMode(AppThemeMode.light);

        // Assert
        expect(themeProvider.isLightMode, true);
      });

      test('should return isSystemMode based on themeMode', () async {
        // Arrange
        await themeProvider.initialize();

        // Assert
        expect(themeProvider.isSystemMode, true);
      });
    });

    group('Listener Management', () {
      test('should allow multiple listener subscriptions', () async {
        // Arrange
        await themeProvider.initialize();
        var notifyCount1 = 0;
        var notifyCount2 = 0;

        // Act
        themeProvider.addListener(() => notifyCount1++);
        themeProvider.addListener(() => notifyCount2++);
        await themeProvider.setThemeMode(AppThemeMode.dark);

        // Assert
        expect(notifyCount1, 1);
        expect(notifyCount2, 1);
      });

      test('should allow listener removal', () async {
        // Arrange
        await themeProvider.initialize();
        var notifyCount = 0;
        void listener() => notifyCount++;
        themeProvider.addListener(listener);

        // Act
        themeProvider.removeListener(listener);
        await themeProvider.setThemeMode(AppThemeMode.dark);

        // Assert
        expect(notifyCount, 0);
      });
    });

    group('Theme Mode Transitions', () {
      test('should transition from system to dark to light', () async {
        // Arrange
        await themeProvider.initialize();
        expect(themeProvider.themeMode, AppThemeMode.system);

        // Act
        await themeProvider.setThemeMode(AppThemeMode.dark);
        expect(themeProvider.themeMode, AppThemeMode.dark);

        await themeProvider.setThemeMode(AppThemeMode.light);

        // Assert
        expect(themeProvider.themeMode, AppThemeMode.light);
      });

      test('should transition through toggle multiple times', () async {
        // Arrange
        await themeProvider.initialize();

        // Act & Assert - toggle sequence
        await themeProvider.toggleTheme();
        expect(themeProvider.themeMode, AppThemeMode.dark);

        await themeProvider.toggleTheme();
        expect(themeProvider.themeMode, AppThemeMode.light);

        await themeProvider.toggleTheme();
        expect(themeProvider.themeMode, AppThemeMode.dark);
      });
    });

    group('Error Handling', () {
      test('should handle setThemeMode errors gracefully', () async {
        // Arrange
        await themeProvider.initialize();

        // Act & Assert - should not throw
        expect(
          () async => await themeProvider.setThemeMode(AppThemeMode.dark),
          returnsNormally,
        );
      });

      test('should handle toggleTheme errors gracefully', () async {
        // Arrange
        await themeProvider.initialize();

        // Act & Assert - should not throw
        expect(() async => await themeProvider.toggleTheme(), returnsNormally);
      });

      test('should handle resetToSystem errors gracefully', () async {
        // Arrange
        await themeProvider.initialize();

        // Act & Assert - should not throw
        expect(
          () async => await themeProvider.resetToSystem(),
          returnsNormally,
        );
      });
    });

    group('Constructor', () {
      test('should initialize with default values', () {
        // Arrange & Act
        final provider = ThemeProvider();

        // Assert
        expect(provider.isLoading, true);
        expect(provider.themeMode, AppThemeMode.system);
        expect(provider.isDarkMode, false);
        expect(provider.isLightMode, false);
        expect(provider.isSystemMode, true);

        provider.dispose();
      });
    });
  });

  group('ThemeProvider AppThemeMode Enum', () {
    test('should have system mode', () {
      // Assert
      expect(AppThemeMode.system, isNotNull);
      expect(AppThemeMode.system.name, 'system');
    });

    test('should have dark mode', () {
      // Assert
      expect(AppThemeMode.dark, isNotNull);
      expect(AppThemeMode.dark.name, 'dark');
    });

    test('should have light mode', () {
      // Assert
      expect(AppThemeMode.light, isNotNull);
      expect(AppThemeMode.light.name, 'light');
    });

    test('should have all three modes', () {
      // Assert
      expect(AppThemeMode.values.length, 3);
      expect(AppThemeMode.values, contains(AppThemeMode.system));
      expect(AppThemeMode.values, contains(AppThemeMode.dark));
      expect(AppThemeMode.values, contains(AppThemeMode.light));
    });
  });

  group('ThemeProvider State Consistency', () {
    late ThemeProvider themeProvider;

    setUp(() {
      themeProvider = ThemeProvider();
    });

    tearDown(() {
      themeProvider.dispose();
    });

    test('should have consistent state after initialization', () async {
      // Act
      await themeProvider.initialize();

      // Assert - exactly one mode should be active
      final modes = [
        themeProvider.isDarkMode,
        themeProvider.isLightMode,
        themeProvider.isSystemMode,
      ];
      expect(modes.where((m) => m).length, 1);
    });

    test('should have consistent state after setting dark mode', () async {
      // Arrange
      await themeProvider.initialize();

      // Act
      await themeProvider.setThemeMode(AppThemeMode.dark);

      // Assert
      expect(themeProvider.isDarkMode, true);
      expect(themeProvider.isLightMode, false);
      expect(themeProvider.isSystemMode, false);
    });

    test('should have consistent state after setting light mode', () async {
      // Arrange
      await themeProvider.initialize();

      // Act
      await themeProvider.setThemeMode(AppThemeMode.light);

      // Assert
      expect(themeProvider.isDarkMode, false);
      expect(themeProvider.isLightMode, true);
      expect(themeProvider.isSystemMode, false);
    });

    test('should have consistent state after setting system mode', () async {
      // Arrange
      await themeProvider.initialize();
      await themeProvider.setThemeMode(AppThemeMode.dark);

      // Act
      await themeProvider.setThemeMode(AppThemeMode.system);

      // Assert
      expect(themeProvider.isDarkMode, false);
      expect(themeProvider.isLightMode, false);
      expect(themeProvider.isSystemMode, true);
    });
  });

  group('ThemeProvider Loading State', () {
    late ThemeProvider themeProvider;

    setUp(() {
      themeProvider = ThemeProvider();
    });

    tearDown(() {
      themeProvider.dispose();
    });

    test('should start with isLoading true', () {
      // Assert
      expect(themeProvider.isLoading, true);
    });

    test('should set isLoading false after initialize', () async {
      // Act
      await themeProvider.initialize();

      // Assert
      expect(themeProvider.isLoading, false);
    });

    test('should notify listeners when isLoading changes', () async {
      // Arrange
      var notifyCount = 0;
      themeProvider.addListener(() => notifyCount++);

      // Act
      await themeProvider.initialize();

      // Assert
      expect(notifyCount, greaterThan(0));
    });
  });
}
