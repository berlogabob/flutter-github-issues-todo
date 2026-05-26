import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// In-memory flutter_secure_storage method-channel double.
class FakeSecureStorage {
  FakeSecureStorage({Map<String, String>? initialValues})
    : _values = Map<String, String>.of(initialValues ?? const {});

  static const MethodChannel channel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final Map<String, String> _values;

  Map<String, String> get values => Map.unmodifiable(_values);

  String? read(String key) => _values[key];

  void write(String key, String value) => _values[key] = value;

  void delete(String key) => _values.remove(key);

  void deleteAll() => _values.clear();

  void reset([Map<String, String>? values]) {
    _values
      ..clear()
      ..addAll(values ?? const {});
  }

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handleMethodCall);
  }

  void dispose() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    _values.clear();
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    final arguments = _arguments(call);
    final key = arguments['key'] as String?;

    switch (call.method) {
      case 'read':
        return key == null ? null : _values[key];
      case 'write':
        final value = arguments['value'] as String?;
        if (key != null && value != null) {
          _values[key] = value;
        }
        return null;
      case 'delete':
        if (key != null) {
          _values.remove(key);
        }
        return null;
      case 'deleteAll':
        _values.clear();
        return null;
      case 'readAll':
        return Map<String, String>.of(_values);
      case 'containsKey':
        return key != null && _values.containsKey(key);
      default:
        throw PlatformException(
          code: 'unimplemented',
          message: 'Unsupported secure storage method: ${call.method}',
        );
    }
  }

  Map<String, Object?> _arguments(MethodCall call) {
    final arguments = call.arguments;
    if (arguments is Map) {
      return arguments.cast<String, Object?>();
    }
    return const {};
  }
}

/// path_provider fake backed by a temporary test directory.
class FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  FakePathProviderPlatform({Directory? rootDirectory})
    : _rootDirectory =
          rootDirectory ??
          Directory.systemTemp.createTempSync('gitdoit_test_') {
    reset();
  }

  final Directory _rootDirectory;
  late Directory _currentDirectory;
  int _resetCount = 0;

  late String temporaryPath;
  late String applicationSupportPath;
  late String libraryPath;
  late String applicationDocumentsPath;
  late String externalStoragePath;
  late String externalCachePath;
  late String downloadsPath;

  Directory get rootDirectory => _rootDirectory;

  void install() => PathProviderPlatform.instance = this;

  void reset() {
    if (!_rootDirectory.existsSync()) {
      _rootDirectory.createSync(recursive: true);
    }

    _currentDirectory = Directory('${_rootDirectory.path}/run_${_resetCount++}')
      ..createSync(recursive: true);

    temporaryPath = _createDirectory('tmp').path;
    applicationSupportPath = _createDirectory('support').path;
    libraryPath = _createDirectory('library').path;
    applicationDocumentsPath = _createDirectory('documents').path;
    externalStoragePath = _createDirectory('external_storage').path;
    externalCachePath = _createDirectory('external_cache').path;
    downloadsPath = _createDirectory('downloads').path;
  }

  Future<void> dispose() async {
    if (await _rootDirectory.exists()) {
      await _rootDirectory.delete(recursive: true);
    }
  }

  @override
  Future<String?> getTemporaryPath() async => temporaryPath;

  @override
  Future<String?> getApplicationSupportPath() async => applicationSupportPath;

  @override
  Future<String?> getLibraryPath() async => libraryPath;

  @override
  Future<String?> getApplicationDocumentsPath() async =>
      applicationDocumentsPath;

  @override
  Future<String?> getExternalStoragePath() async => externalStoragePath;

  @override
  Future<List<String>?> getExternalCachePaths() async => [externalCachePath];

  @override
  Future<String?> getDownloadsPath() async => downloadsPath;

  Directory _createDirectory(String name) {
    final directory = Directory('${_currentDirectory.path}/$name');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return directory;
  }
}

/// connectivity_plus method/event-channel double.
class FakeConnectivity {
  FakeConnectivity({List<String> initialResults = const ['none']})
    : _results = List<String>.of(initialResults);

  static const MethodChannel methodChannel = MethodChannel(
    'dev.fluttercommunity.plus/connectivity',
  );
  static const EventChannel eventChannel = EventChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  static const MethodChannel _eventMethodChannel = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );

  List<String> _results;

  List<String> get results => List.unmodifiable(_results);

  void reset({List<String> results = const ['none']}) {
    _results = List<String>.of(results);
  }

  void setOnline() => reset(results: const ['wifi']);

  void setOffline() => reset();

  void install() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    messenger
      ..setMockMethodCallHandler(methodChannel, handleMethodCall)
      ..setMockMethodCallHandler(_eventMethodChannel, handleEventCall);
  }

  void dispose() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    messenger
      ..setMockMethodCallHandler(methodChannel, null)
      ..setMockMethodCallHandler(_eventMethodChannel, null);
    setOffline();
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'check':
        return List<String>.of(_results);
      default:
        throw PlatformException(
          code: 'unimplemented',
          message: 'Unsupported connectivity method: ${call.method}',
        );
    }
  }

  Future<dynamic> handleEventCall(MethodCall call) async {
    switch (call.method) {
      case 'listen':
        Future<void>.microtask(() {
          final encoded = eventChannel.codec.encodeSuccessEnvelope(
            List<String>.of(_results),
          );
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .handlePlatformMessage(eventChannel.name, encoded, null);
        });
        return null;
      case 'cancel':
        return null;
      default:
        throw PlatformException(
          code: 'unimplemented',
          message: 'Unsupported connectivity event method: ${call.method}',
        );
    }
  }
}

/// Installs deterministic package_info_plus values for tests.
void installPackageInfoMock({
  String appName = 'GitDoIt',
  String packageName = 'com.example.gitdoit',
  String version = '0.5.0',
  String buildNumber = '133',
  String buildSignature = '',
  String installerStore = '',
}) {
  PackageInfo.setMockInitialValues(
    appName: appName,
    packageName: packageName,
    version: version,
    buildNumber: buildNumber,
    buildSignature: buildSignature,
    installerStore: installerStore,
  );
}

/// HttpOverrides that fails every attempted network request.
class NoNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _NoNetworkHttpClient();
}

class _NoNetworkHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) => Future.error(
    SocketException('Network is disabled in tests: $method $url'),
  );

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('DELETE', url);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('PATCH', url);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('HEAD', url);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
