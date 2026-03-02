import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'constants/app_colors.dart';
import 'utils/app_error_handler.dart';
import 'services/secure_storage_service.dart';
import 'services/network_service.dart';
import 'providers/app_providers.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_dashboard_screen.dart';

// Authentication state provider using singleton
final authStateProvider = FutureProvider<AuthState>((ref) async {
  try {
    final token = await SecureStorageService.getToken();
    final authType = await SecureStorageService.instance.read(key: 'auth_type');

    debugPrint('Auth check - Token exists: ${token != null}, Type: $authType');

    if (token != null && token.isNotEmpty) {
      return AuthState(
        isAuthenticated: true,
        authType: authType ?? 'unknown',
        token: token,
      );
    }

    return AuthState(isAuthenticated: false, authType: 'none', token: null);
  } catch (e) {
    debugPrint('Auth check error: $e');
    return AuthState(isAuthenticated: false, authType: 'error', token: null);
  }
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for caching
  await Hive.initFlutter();

  // Initialize NetworkService
  await NetworkService().init();

  // Add Flutter error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    AppErrorHandler.handle(
      details.exception,
      stackTrace: details.stack,
      showSnackBar: false, // Don't show SnackBar for Flutter errors
    );
  };

  WidgetsBinding.instance.platformDispatcher.onError =
      (Object error, StackTrace stack) {
        AppErrorHandler.handle(
          error,
          stackTrace: stack,
          showSnackBar: false, // Don't show SnackBar for platform errors
        );
        return true;
      };

  // Check if user is already logged in using singleton
  String? token;
  String? authType;

  try {
    token = await SecureStorageService.getToken();
    authType = await SecureStorageService.instance.read(key: 'auth_type');
  } catch (e) {
    debugPrint('Error reading from secure storage: $e');
  }

  debugPrint(
    'App start - Token: ${token != null ? "exists" : "none"}, AuthType: $authType',
  );

  runApp(
    ProviderScope(
      child: GitDoItApp(initialToken: token, initialAuthType: authType),
    ),
  );

  // Cleanup on app exit
  WidgetsBinding.instance.addPostFrameCallback((_) {
    NetworkService().dispose();
  });
}

class GitDoItApp extends StatelessWidget {
  final String? initialToken;
  final String? initialAuthType;

  const GitDoItApp({super.key, this.initialToken, this.initialAuthType});

  @override
  Widget build(BuildContext context) {
    // If user is already logged in (or in offline mode), go to dashboard
    final isLoggedIn =
        (initialToken?.isNotEmpty ?? false) || initialAuthType == 'offline';

    debugPrint(
      'GitDoItApp build - isLoggedIn: $isLoggedIn, AuthType: $initialAuthType',
    );

    return ScreenUtilInit(
      designSize: const Size(360, 690), // iPhone 6/7/8 base size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'GitDoIt',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.background,
            primaryColor: AppColors.orangePrimary,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.orangePrimary,
              secondary: AppColors.red,
              surface: AppColors.cardBackground,
              error: AppColors.red,
              onPrimary: Colors.black,
              onSecondary: Colors.white,
              onSurface: Colors.white,
              onError: Colors.white,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.background,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              color: AppColors.cardBackground,
              elevation: 2,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orangePrimary,
                foregroundColor: Colors.black,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppColors.orangePrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0x4DFFFFFF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.orangePrimary),
              ),
            ),
            fontFamily: '.SF Pro Text',
            useMaterial3: true,
          ),
          home: isLoggedIn
              ? const MainDashboardScreen()
              : const OnboardingScreen(),
        );
      },
    );
  }
}
