import 'package:go_router/go_router.dart';
import 'screens/main_dashboard_screen.dart';
import 'screens/onboarding_screen.dart';

/// Centralized route definitions for the app.
abstract final class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';
}

/// Router factory for app startup/auth state.
abstract final class AppRouter {
  static GoRouter create({required bool initiallyLoggedIn}) {
    return GoRouter(
      initialLocation: initiallyLoggedIn
          ? AppRoutes.dashboard
          : AppRoutes.onboarding,
      routes: [
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const MainDashboardScreen(),
        ),
      ],
    );
  }
}
