import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'providers/auth_provider.dart';
import 'providers/issues_provider.dart';
import 'providers/theme_provider.dart';
import 'services/theme_prefs.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/debug_screen.dart';
import 'utils/logging.dart';
import 'theme/app_theme.dart';
import 'models/issue.adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(IssueAdapter());
  Hive.registerAdapter(LabelAdapter());
  Hive.registerAdapter(MilestoneAdapter());
  Hive.registerAdapter(UserAdapter());

  Logger.i('App starting', context: 'Main');
  Logger.i('Hive initialized', context: 'Main');

  // Track app start journey event
  Logger.trackJourney(
    JourneyEventType.screenView,
    'Main',
    'app_started',
    metadata: {'version': '0.2.0'},
  );

  runApp(const GitDoItApp());
}

/// GitDoIt - GitHub Issues TODO Tool
///
/// Industrial Minimalism Redesign (v0.2.0)
/// - Custom theme system (Material themed beyond recognition)
/// - Design tokens (colors, typography, spacing, elevation, animations)
/// - Atomic widget library
/// - Z-axis spatial depth
/// - Spring physics animations
class GitDoItApp extends StatelessWidget {
  const GitDoItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadSavedToken()),
        ChangeNotifierProvider(
          create: (context) {
            final issuesProvider = IssuesProvider();
            issuesProvider.initialize();
            return issuesProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'GitDoIt',
            debugShowCheckedModeBanner: false,

            // Industrial Minimalism Theme
            theme: IndustrialAppTheme.lightTheme,
            darkTheme: IndustrialAppTheme.darkTheme,
            themeMode: _getThemeMode(themeProvider.themeMode),

            home: const AuthWrapper(),
            routes: {
              '/auth': (context) => const AuthScreen(),
              '/home': (context) => const HomeScreen(),
              '/debug': (context) => const DebugScreen(),
            },
          );
        },
      ),
    );
  }

  /// Convert AppThemeMode to ThemeMode
  ThemeMode _getThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// Authentication Wrapper - Decides which screen to show
///
/// Smart First Screen Logic:
/// - Logged in + repo configured → HomeScreen (Todos)
/// - Not logged in OR no repo → AuthScreen (login/offline)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.d('Building AuthWrapper', context: 'Navigation');

    return Consumer2<AuthProvider, IssuesProvider>(
      builder: (context, authProvider, issuesProvider, _) {
        // Smart first screen decision matrix
        final isAuthenticated = authProvider.isAuthenticated;
        final hasRepo = issuesProvider.hasRepoConfig;

        if (isAuthenticated && hasRepo) {
          // User logged in AND repository configured → Go to HomeScreen
          Logger.d(
            'User authenticated + repo configured, showing HomeScreen',
            context: 'Navigation',
          );
          Logger.trackJourney(
            JourneyEventType.screenView,
            'Navigation',
            'show_home',
            metadata: {'username': authProvider.username},
          );
          return const HomeScreen();
        } else {
          // Not authenticated OR no repo configured → Show AuthScreen
          Logger.d(
            'User not authenticated or no repo, showing AuthScreen',
            context: 'Navigation',
            metadata: {
              'is_authenticated': isAuthenticated,
              'has_repo_config': hasRepo,
            },
          );
          Logger.trackJourney(
            JourneyEventType.screenView,
            'Navigation',
            'show_auth',
            metadata: {
              'is_authenticated': isAuthenticated,
              'has_repo_config': hasRepo,
            },
          );
          return const AuthScreen();
        }
      },
    );
  }
}
