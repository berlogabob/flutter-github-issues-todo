import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Mock implementation of FlutterSecureStorage for testing
class MockSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> write({
    required String key,
    String? value,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    _storage[key] = value ?? '';
  }

  @override
  Future<void> delete({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll({
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    _storage.clear();
  }

  @override
  Future<bool> containsKey({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    return _storage.containsKey(key);
  }

  @override
  Future<Map<String, String>> readAll({
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    return Map.from(_storage);
  }
}

/// Mock HTTP Client for testing
class MockHttpClient implements http.Client {
  int statusCode = 200;
  dynamic responseBody;
  Map<String, String>? responseHeaders;
  bool shouldThrow = false;
  String? throwMessage;

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    if (shouldThrow) {
      throw http.ClientException(throwMessage ?? 'Network error');
    }
    return http.Response(
      json.encode(responseBody ?? {}),
      statusCode,
      headers: responseHeaders ?? <String, String>{},
    );
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    body,
    Encoding? encoding,
  }) async {
    if (shouldThrow) {
      throw http.ClientException(throwMessage ?? 'Network error');
    }
    return http.Response(
      json.encode(responseBody ?? {}),
      statusCode,
      headers: responseHeaders ?? <String, String>{},
    );
  }

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    body,
    Encoding? encoding,
  }) async {
    if (shouldThrow) {
      throw http.ClientException(throwMessage ?? 'Network error');
    }
    return http.Response(
      json.encode(responseBody ?? {}),
      statusCode,
      headers: responseHeaders ?? <String, String>{},
    );
  }

  @override
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    body,
    Encoding? encoding,
  }) async {
    if (shouldThrow) {
      throw http.ClientException(throwMessage ?? 'Network error');
    }
    return http.Response(
      json.encode(responseBody ?? {}),
      statusCode,
      headers: responseHeaders ?? <String, String>{},
    );
  }

  @override
  Future<http.Response> delete(Uri url, {Map<String, String>? headers}) async {
    if (shouldThrow) {
      throw http.ClientException(throwMessage ?? 'Network error');
    }
    return http.Response(
      json.encode(responseBody ?? {}),
      statusCode,
      headers: responseHeaders ?? <String, String>{},
    );
  }

  @override
  Future<http.Response> read(Uri url, {Map<String, String>? headers}) async {
    if (shouldThrow) {
      throw http.ClientException(throwMessage ?? 'Network error');
    }
    return http.Response(
      json.encode(responseBody ?? {}),
      statusCode,
      headers: responseHeaders ?? <String, String>{},
    );
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(Stream.empty(), 200);
  }

  @override
  void close() {}
}
