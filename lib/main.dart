import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'constants/app_colors.dart';
import 'utils/app_error_handler.dart';
import 'services/secure_storage_service.dart';
import 'services/network_service.dart';
import 'services/sync_service.dart';
import 'services/local_storage_service.dart';
import 'services/cache_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_dashboard_screen.dart';

// Background sync task name
const String _backgroundSyncTask = 'background_sync_task';

// Background task callback (must be top-level function)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Background sync task started: $task');

    try {
      // Initialize required services
      await Hive.initFlutter();
      final localStorage = LocalStorageService();
      final syncService = SyncService();

      // Load auto-sync settings
      final autoSyncWifi = await localStorage.getAutoSyncWifi();
      final autoSyncAny = await localStorage.getAutoSyncAny();

      debugPrint('Auto-sync settings - WiFi: $autoSyncWifi, Any: $autoSyncAny');

      // Check if auto-sync is enabled
      if (!autoSyncWifi && !autoSyncAny) {
        debugPrint('Auto-sync disabled, skipping background sync');
        return true;
      }

      // Check for pending operations
      // Note: We can't directly access PendingOperationsService here due to isolation
      // The sync service will handle this during syncAll()

      // Initialize and run sync
      syncService.init();
      final result = await syncService.syncAll(forceRefresh: false);

      debugPrint('Background sync completed: $result');
      return result;
    } catch (e, stackTrace) {
      debugPrint('Background sync error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for caching
  await Hive.initFlutter();

  // Initialize CacheService for API response caching
  await CacheService().init();
  debugPrint('CacheService initialized');

  // Initialize NetworkService
  await NetworkService().init();

  // PERFORMANCE OPTIMIZATION (Task 16.3): Initialize Workmanager for background sync
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false, // Set to false in production
  );

  // Register periodic background sync task
  // Sync every 15 minutes (minimum interval allowed by Android)
  // WiFi check is done in the callback based on user settings
  await Workmanager().registerPeriodicTask(
    _backgroundSyncTask,
    _backgroundSyncTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected, // Requires network connection
      requiresBatteryNotLow: true, // Don't run if battery is low
      requiresCharging: false, // Don't require charging
      requiresDeviceIdle: false, // Run even if device is not idle
    ),
  );
  debugPrint('Background sync registered (every 15 minutes)');

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
