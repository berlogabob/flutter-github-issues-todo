import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'constants/app_colors.dart';
import 'services/secure_storage_service.dart';
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

    return AuthState(
      isAuthenticated: false,
      authType: 'none',
      token: null,
    );
  } catch (e) {
    debugPrint('Auth check error: $e');
    return AuthState(
      isAuthenticated: false,
      authType: 'error',
      token: null,
    );
  }
});

class AuthState {
  final bool isAuthenticated;
  final String authType;
  final String? token;
  
  AuthState({
    required this.isAuthenticated,
    required this.authType,
    required this.token,
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if user is already logged in using singleton
  final token = await SecureStorageService.getToken();
  final authType = await SecureStorageService.instance.read(key: 'auth_type');

  debugPrint('App start - Token: ${token != null ? "exists" : "none"}, AuthType: $authType');

  runApp(
    ProviderScope(
      child: GitDoItApp(
        initialToken: token,
        initialAuthType: authType,
      ),
    ),
  );
}

class GitDoItApp extends StatelessWidget {
  final String? initialToken;
  final String? initialAuthType;
  
  const GitDoItApp({
    super.key,
    this.initialToken,
    this.initialAuthType,
  });

  @override
  Widget build(BuildContext context) {
    // If user is already logged in, go to dashboard
    final isLoggedIn = initialToken != null && initialToken!.isNotEmpty;

    debugPrint('GitDoItApp build - isLoggedIn: $isLoggedIn');

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
            primaryColor: AppColors.orange,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.orange,
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
                backgroundColor: AppColors.orange,
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
                side: const BorderSide(color: AppColors.orange),
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
                borderSide: BorderSide(color: AppColors.orange),
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
