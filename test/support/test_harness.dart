import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/services/cache_service.dart';
import 'package:gitdoit/services/pending_operations_service.dart';
import 'package:hive_ce/hive_ce.dart';

import 'platform_mocks.dart';

/// Shared platform harness for widget and service tests.
class TestHarness {
  TestHarness({
    FakeSecureStorage? secureStorage,
    FakePathProviderPlatform? pathProvider,
    FakeConnectivity? connectivity,
    HttpOverrides? httpOverrides,
  }) : secureStorage = secureStorage ?? FakeSecureStorage(),
       pathProvider = pathProvider ?? FakePathProviderPlatform(),
       connectivity = connectivity ?? FakeConnectivity(),
       httpOverrides = httpOverrides ?? NoNetworkHttpOverrides();

  static final TestHarness shared = TestHarness();

  final FakeSecureStorage secureStorage;
  final FakePathProviderPlatform pathProvider;
  final FakeConnectivity connectivity;
  final HttpOverrides httpOverrides;

  HttpOverrides? _previousHttpOverrides;
  bool _isInstalled = false;
  bool _isHiveInitialized = false;

  static const Size defaultScreenSize = Size(360, 690);

  /// Installs Flutter test bindings and platform mocks.
  Future<void> install() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    if (!_isInstalled) {
      _previousHttpOverrides = HttpOverrides.current;
      _isInstalled = true;
    }

    WidgetsFlutterBinding.ensureInitialized();
    secureStorage.install();
    pathProvider.install();
    connectivity.install();
    _initHive();
    installPackageInfoMock();
    configureScreenUtil();
    HttpOverrides.global = httpOverrides;
  }

  /// Clears mutable fake state while keeping mocks installed.
  Future<void> reset({Map<String, String>? secureStorageValues}) async {
    await _resetHiveBackedServices();
    secureStorage.reset(secureStorageValues);
    pathProvider.reset();
    _ensureHiveDirectory();
    connectivity.reset();
    installPackageInfoMock();
    configureScreenUtil();
    HttpOverrides.global = httpOverrides;
  }

  /// Seeds ScreenUtil for tests that pump screens without ScreenUtilInit.
  void configureScreenUtil({
    Size designSize = defaultScreenSize,
    Size screenSize = defaultScreenSize,
  }) {
    ScreenUtil.configure(
      data: MediaQueryData(size: screenSize),
      designSize: designSize,
      minTextAdapt: true,
      splitScreenMode: false,
    );
  }

  /// Removes method-channel handlers and restores global overrides.
  Future<void> dispose() async {
    await _resetHiveBackedServices();
    secureStorage.dispose();
    connectivity.dispose();
    HttpOverrides.global = _previousHttpOverrides;
    await pathProvider.dispose();
    _isInstalled = false;
  }

  void _initHive() {
    if (_isHiveInitialized) return;

    final hiveDirectory = _ensureHiveDirectory();
    Hive.init(hiveDirectory.path);
    _isHiveInitialized = true;
  }

  Directory _ensureHiveDirectory() {
    final hiveDirectory = Directory('${pathProvider.rootDirectory.path}/hive');
    if (!hiveDirectory.existsSync()) {
      hiveDirectory.createSync(recursive: true);
    }
    return hiveDirectory;
  }

  Future<void> _resetHiveBackedServices() async {
    if (!_isHiveInitialized) return;

    await CacheService().resetForTesting();
    await PendingOperationsService().resetForTesting();

    for (final boxName in const ['cache', 'pending_operations']) {
      try {
        await Hive.deleteBoxFromDisk(boxName);
      } catch (_) {
        // The box may not exist for tests that never touched the service.
      }
    }
  }
}
