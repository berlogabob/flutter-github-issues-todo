import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'test_support.dart';

void main() {
  group('TestHarness', () {
    test('mocks secure storage method channel', () async {
      const storage = FlutterSecureStorage();

      await storage.write(key: 'github_token', value: 'token-123');

      expect(await storage.read(key: 'github_token'), 'token-123');
      expect(await storage.containsKey(key: 'github_token'), isTrue);
      expect(
        await storage.readAll(),
        containsPair('github_token', 'token-123'),
      );

      await storage.delete(key: 'github_token');

      expect(await storage.read(key: 'github_token'), isNull);
    });

    test('mocks package info values', () async {
      final packageInfo = await PackageInfo.fromPlatform();

      expect(packageInfo.appName, 'GitDoIt');
      expect(packageInfo.packageName, 'com.example.gitdoit');
      expect(packageInfo.version, '0.5.0');
      expect(packageInfo.buildNumber, '133');
    });

    test('mocks path provider directories', () async {
      final documents = await getApplicationDocumentsDirectory();
      final temporary = await getTemporaryDirectory();

      expect(documents.existsSync(), isTrue);
      expect(temporary.existsSync(), isTrue);
      expect(documents.path, contains('documents'));
      expect(temporary.path, contains('tmp'));
    });

    test('mocks connectivity status as offline by default', () async {
      final results = await Connectivity().checkConnectivity();

      expect(results, [ConnectivityResult.none]);
    });

    test('allows connectivity status to be overridden', () async {
      TestHarness.shared.connectivity.setOnline();

      final results = await Connectivity().checkConnectivity();

      expect(results, [ConnectivityResult.wifi]);
    });

    test('blocks raw HTTP requests', () async {
      final client = HttpClient();

      await expectLater(
        client.getUrl(Uri.parse('https://example.com/avatar.png')),
        throwsA(isA<SocketException>()),
      );
    });

    testWidgets('pumps widgets with Material, Riverpod, and ScreenUtil', (
      tester,
    ) async {
      await tester.pumpTestApp(
        const Scaffold(body: Center(child: Text('ready'))),
      );

      expect(find.text('ready'), findsOneWidget);
    });
  });
}
