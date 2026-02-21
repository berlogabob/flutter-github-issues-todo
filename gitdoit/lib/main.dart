import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'providers/auth_provider.dart';
import 'providers/issues_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'utils/logger.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  // Note: Adapters will be added when models are properly configured for Hive

  Logger.i('Hive initialized', context: 'Main');

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
      ],
      child: MaterialApp(
        title: 'GitDoIt',
        debugShowCheckedModeBanner: false,

        // Industrial Minimalism Theme
        theme: IndustrialAppTheme.lightTheme,
        darkTheme: IndustrialAppTheme.darkTheme,
        themeMode: ThemeMode.system,

        home: const AuthWrapper(),
        routes: {
          '/auth': (context) => const AuthScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

/// Authentication Wrapper - Decides which screen to show
///
/// Shows AuthScreen if not authenticated, HomeScreen if authenticated
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.d('Building AuthWrapper', context: 'Navigation');

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Check authentication state
        if (authProvider.isAuthenticated) {
          Logger.d(
            'User authenticated, showing HomeScreen',
            context: 'Navigation',
          );
          return const HomeScreen();
        } else {
          Logger.d(
            'User not authenticated, showing AuthScreen',
            context: 'Navigation',
          );
          return const AuthScreen();
        }
      },
    );
  }
}
