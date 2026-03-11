import 'package:flutter/material.dart';

/// Application color palette - SIMPLIFIED & FLATTENED
///
/// Reduced from 19 to 12 colors by removing duplicates and using opacity variants.
/// All colors optimized for dark theme with orange as primary accent.
class AppColors {
  // ========== BACKGROUNDS (3 colors) ==========

  /// Main background (#121212) - replaced backgroundGradientStart
  static const Color background = Color(0xFF121212);

  /// Card/surface background (#1E1E1E) - replaced backgroundGradientEnd, cardBackground
  static const Color card = Color(0xFF1E1E1E);

  /// Deep background (#0A0A0A) - replaced surfaceColor, darkBackground
  static const Color dark = Color(0xFF0A0A0A);

  // ========== ACCENTS (3 colors) ==========

  /// Primary orange (#FF6200) - use withOpacity() for variants instead of orangeLight
  static const Color primary = Color(0xFFFF6200);

  /// Blue for links/projects (#0A84FF)
  static const Color link = Color(0xFF0A84FF);

  /// Red for errors/closed (#FF3B30) - replaced error (was duplicate)
  static const Color error = Color(0xFFFF3B30);

  // ========== STATUS (3 colors) ==========

  /// Success/open state (#4CAF50) - replaced issueOpen
  static const Color success = Color(0xFF4CAF50);

  /// Warning (#FFC107)
  static const Color warning = Color(0xFFFFC107);

  /// Closed/merged state (#6E7781) - replaced issueClosed
  static const Color muted = Color(0xFF6E7781);

  // ========== TEXT & BORDERS (3 colors) ==========

  /// Primary text (#FFFFFF)
  static const Color text = Color(0xFFFFFFFF);

  /// Secondary text (#A0A0A5)
  static const Color textSecondary = Color(0xFFA0A0A5);

  /// Borders/dividers (#333333)
  static const Color border = Color(0xFF333333);

  // ========== DEPRECATED (for backward compatibility - remove in next major version) ==========

  @Deprecated('Use background instead')
  static Color get backgroundGradientStart => background;

  @Deprecated('Use card instead')
  static Color get backgroundGradientEnd => card;

  @Deprecated('Use card instead')
  static Color get cardBackground => card;

  @Deprecated('Use primary instead')
  static Color get orangePrimary => primary;

  @Deprecated('Use primary.withOpacity(0.8) instead')
  static Color get orangeLight => primary.withValues(alpha: 0.8);

  @Deprecated('Use primary instead')
  static Color get orangeSecondary => primary;

  @Deprecated('Use error instead')
  static Color get red => error;

  @Deprecated('Use text instead')
  static Color get white => text;

  @Deprecated('Use success instead')
  static Color get issueOpen => success;

  @Deprecated('Use muted instead')
  static Color get issueClosed => muted;

  @Deprecated('Use dark instead')
  static Color get surfaceColor => dark;

  @Deprecated('Use dark instead')
  static Color get darkBackground => dark;

  @Deprecated('Use border instead')
  static Color get borderColor => border;

  @Deprecated('Use textSecondary instead')
  static Color get secondaryText => textSecondary;
}

/// Application typography constants.
///
/// Defines font family, sizes, and weights for consistent text styling.
/// Uses SF Pro Text font family for iOS-style typography.
class AppTypography {
  /// Font family name for SF Pro Text.
  static const String fontFamily = '.SF Pro Text';

  /// Large title font size (32.0sp) for screen headers.
  static const double titleLarge = 32.0;

  /// Medium title font size (20.0sp) for section headers.
  static const double titleMedium = 20.0;

  /// Small title font size (16.0sp) for subsection headers.
  static const double titleSmall = 16.0;

  /// Large body text font size (14.0sp) for primary content.
  static const double bodyLarge = 14.0;

  /// Medium body text font size (14.0sp) for standard content.
  static const double bodyMedium = 14.0;

  /// Small label font size (12.0sp) for captions and hints.
  static const double labelSmall = 12.0;

  /// Caption font size (11.0sp) for secondary information.
  static const double caption = 11.0;

  /// Bold font weight for emphasis.
  static const FontWeight bold = FontWeight.bold;

  /// Medium font weight for semi-bold text.
  static const FontWeight medium = FontWeight.w500;

  /// Regular font weight for normal text.
  static const FontWeight regular = FontWeight.normal;
}

/// Application spacing constants.
///
/// Defines consistent spacing values throughout the app.
/// Based on 4px grid system for visual harmony.
class AppSpacing {
  /// Extra small spacing (4.0px) for tight layouts.
  static const double xs = 4.0;

  /// Small spacing (8.0px) for compact layouts.
  static const double sm = 8.0;

  /// Medium spacing (16.0px) for standard layouts.
  static const double md = 16.0;

  /// Large spacing (24.0px) for generous layouts.
  static const double lg = 24.0;

  /// Extra large spacing (32.0px) for wide layouts.
  static const double xl = 32.0;
}

/// Application border radius constants.
///
/// Defines consistent corner rounding throughout the app.
/// Used for cards, buttons, and input fields.
class AppBorderRadius {
  /// Small border radius (4.0px) for subtle rounding.
  static const double sm = 4.0;

  /// Medium border radius (8.0px) for standard rounding.
  static const double md = 8.0;

  /// Large border radius (12.0px) for prominent rounding.
  static const double lg = 12.0;

  /// Extra large border radius (16.0px) for maximum rounding.
  static const double xl = 16.0;
}

/// Application configuration constants.
///
/// Defines app metadata, API endpoints, and sync settings.
/// Used for global app configuration and GitHub API integration.
class AppConfig {
  /// Application display name.
  static const String appName = 'GitDoIt';

  /// Application version string.
  static const String appVersion = '1.0.0';

  /// GitHub REST API base URL.
  static const String githubApiBase = 'https://api.github.com';

  /// GitHub GraphQL API endpoint.
  static const String githubGraphQl = 'https://api.github.com/graphql';

  /// Required OAuth scopes for GitHub API access.
  /// Includes repo, org management, and project permissions.
  static const List<String> requiredScopes = [
    'repo',
    'read:org',
    'write:org',
    'project',
  ];

  /// Default sync interval for automatic synchronization.
  static const Duration syncInterval = Duration(minutes: 5);

  /// Maximum number of items that can be stored offline.
  static const int maxOfflineItems = 1000;
}
