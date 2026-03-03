import 'package:flutter/material.dart';

/// Application color palette following the brief's visual style.
///
/// All colors are optimized for dark theme with orange as primary accent.
/// Used throughout the app for consistent branding and UI elements.
class AppColors {
  /// Dark background color (#121212) for main app surfaces.
  static const Color background = Color(0xFF121212);

  /// Gradient start color for background transitions.
  static const Color backgroundGradientStart = Color(0xFF121212);

  /// Gradient end color for background transitions.
  static const Color backgroundGradientEnd = Color(0xFF1E1E1E);

  /// Card background color (#1E1E1E) for elevated surfaces.
  static const Color cardBackground = Color(0xFF1E1E1E);

  /// Primary orange accent color (#FF6200) for main actions and highlights.
  static const Color orangePrimary = Color(0xFFFF6200);

  /// Secondary orange color for variations and hover states.
  static const Color orangeLight = Color(0xFFFF8A33);

  /// Red color (#FF3B30) for errors, destructive actions, and closed states.
  static const Color red = Color(0xFFFF3B30);

  /// Blue color (#0A84FF) for links, info, and project-related elements.
  static const Color blue = Color(0xFF0A84FF);

  /// White color (#FFFFFF) for primary text on dark backgrounds.
  static const Color white = Color(0xFFFFFFFF);

  /// Green color (#4CAF50) for success states and confirmations.
  static const Color success = Color(0xFF4CAF50);

  /// Error color (#FF3B30) matching red for consistency.
  static const Color error = Color(0xFFFF3B30);

  /// Warning color (#FFC107) for caution indicators.
  static const Color warning = Color(0xFFFFC107);

  /// Open issue status color (#238636) - GitHub-style green.
  static const Color issueOpen = Color(0xFF238636);

  /// Closed issue status color (#6E7781) - GitHub-style gray.
  static const Color issueClosed = Color(0xFF6E7781);

  /// Secondary orange color from new design (#FF5E00).
  static const Color orangeSecondary = Color(0xFFFF5E00);

  /// Secondary text color (#A0A0A5) for less prominent text.
  static const Color secondaryText = Color(0xFFA0A0A5);

  /// Surface color (#111111) for elevated components.
  static const Color surfaceColor = Color(0xFF111111);

  /// Border color (#333333) for dividers and outlines.
  static const Color borderColor = Color(0xFF333333);

  /// Dark background color (#0A0A0A) for deepest surfaces.
  static const Color darkBackground = Color(0xFF0A0A0A);
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
