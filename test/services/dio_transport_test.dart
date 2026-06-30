import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/services/github_api_service.dart';
import 'package:gitdoit/services/oauth_service.dart';
import 'package:gitdoit/services/secure_storage_service.dart';

void main() {
  test('GitHub service parses Dio responses', () async {
    await SecureStorageService.saveToken('ghp_test_token_1234567890');
    final adapter = _FakeAdapter(
      (options) => _jsonResponse({
        'node_id': 'repo-node',
        'name': 'repo',
        'full_name': 'owner/repo',
        'description': 'Test repository',
        'open_issues_count': 2,
      }),
    );
    final dio = Dio()..httpClientAdapter = adapter;

    final repo = await GitHubApiService(
      dio: dio,
    ).fetchRepoByUrl('owner', 'repo');

    expect(repo?.fullName, 'owner/repo');
    expect(repo?.openIssuesCount, 2);
    expect(adapter.lastOptions?.method, 'GET');
    expect(adapter.lastOptions?.uri.path, '/repos/owner/repo');
  });

  test('OAuth device request is form encoded through Dio', () async {
    final adapter = _FakeAdapter(
      (options) => _jsonResponse({
        'device_code': 'device-code',
        'user_code': 'ABCD-1234',
        'verification_uri': 'https://github.com/login/device',
        'expires_in': 900,
        'interval': 5,
      }),
    );
    final dio = Dio()..httpClientAdapter = adapter;

    final result = await OAuthService(
      dio: dio,
      clientId: 'Iv1.test',
    ).requestDeviceCode();

    expect(result?.userCode, 'ABCD-1234');
    expect(adapter.lastOptions?.contentType, Headers.formUrlEncodedContentType);
    expect(adapter.lastOptions?.data, containsPair('client_id', 'Iv1.test'));
  });

  test('GitHub service maps Dio connection failures', () async {
    await SecureStorageService.saveToken('ghp_test_token_1234567890');
    final adapter = _FakeAdapter(
      (options) => throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ),
    );
    final dio = Dio()..httpClientAdapter = adapter;

    await expectLater(
      GitHubApiService(dio: dio).getCurrentUser(),
      throwsA(
        predicate(
          (error) => error.toString().contains('Cannot connect to GitHub'),
        ),
      ),
    );
  });

  test('GitHub service maps Dio timeouts', () async {
    await SecureStorageService.saveToken('ghp_test_token_1234567890');
    final adapter = _FakeAdapter(
      (options) => throw DioException(
        requestOptions: options,
        type: DioExceptionType.receiveTimeout,
      ),
    );
    final dio = Dio()..httpClientAdapter = adapter;

    await expectLater(
      GitHubApiService(dio: dio).getCurrentUser(),
      throwsA(
        predicate(
          (error) => error.toString().contains('Cannot connect to GitHub'),
        ),
      ),
    );
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final FutureOr<ResponseBody> Function(RequestOptions options) handler;
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Map<String, dynamic> body) {
  return ResponseBody.fromString(
    json.encode(body),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
