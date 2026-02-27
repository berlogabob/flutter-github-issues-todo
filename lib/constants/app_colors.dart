import 'package:flutter/material.dart';

/// App color constants following the brief's visual style
class AppColors {
  // Background
  static const Color background = Color(0xFF121212);
  static const Color backgroundGradientStart = Color(0xFF121212);
  static const Color backgroundGradientEnd = Color(0xFF1E1E1E);
  static const Color cardBackground = Color(0xFF1E1E1E);

  // Accent colors
  static const Color orange = Color(0xFFFF6200);
  static const Color orangeLight = Color(0xFFFF8A33);
  static const Color red = Color(0xFFFF3B30);
  static const Color blue = Color(0xFF0A84FF);

  // Text
  static const Color white = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFFC107);

  // Issue status colors (GitHub-style)
  static const Color issueOpen = Color(0xFF238636);
  static const Color issueClosed = Color(0xFF6E7781);

  // New design colors (from React design)
  static const Color orangeAccent = Color(0xFFFF5E00);
  static const Color secondaryText = Color(0xFFA0A0A5);
  static const Color surfaceColor = Color(0xFF111111);
  static const Color borderColor = Color(0xFF333333);
  static const Color darkBackground = Color(0xFF0A0A0A);
}

/// App typography constants
class AppTypography {
  static const String fontFamily = '.SF Pro Text';

  static const double titleLarge = 32.0;
  static const double titleMedium = 20.0;
  static const double titleSmall = 16.0;
  static const double bodyLarge = 14.0;
  static const double bodyMedium = 14.0;
  static const double labelSmall = 12.0;
  static const double caption = 11.0;

  static const FontWeight bold = FontWeight.bold;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight regular = FontWeight.normal;
}

/// App spacing constants
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

/// App border radius constants
class AppBorderRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
}

/// App configuration
class AppConfig {
  static const String appName = 'GitDoIt';
  static const String appVersion = '1.0.0';

  // GitHub API
  static const String githubApiBase = 'https://api.github.com';
  static const String githubGraphQl = 'https://api.github.com/graphql';

  // Required OAuth scopes
  static const List<String> requiredScopes = [
    'repo',
    'read:org',
    'write:org',
    'project',
  ];

  // Sync settings
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxOfflineItems = 1000;
}
