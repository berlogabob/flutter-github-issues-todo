import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Centralized Dio client for GitHub API requests.
class GitHubDioClient {
  GitHubDioClient._();

  static final Dio instance =
      Dio(
          BaseOptions(
            baseUrl: 'https://api.github.com',
            connectTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: const {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'GitDoIt-App',
            },
            validateStatus: (status) => status != null,
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              debugPrint(
                'GitHubDioClient: ${options.method} ${options.uri.path}${options.uri.query.isNotEmpty ? '?${options.uri.query}' : ''}',
              );
              handler.next(options);
            },
            onResponse: (response, handler) {
              debugPrint(
                'GitHubDioClient: ${response.requestOptions.method} ${response.requestOptions.uri.path} -> ${response.statusCode}',
              );
              handler.next(response);
            },
            onError: (error, handler) {
              debugPrint(
                'GitHubDioClient: ${error.requestOptions.method} ${error.requestOptions.uri.path} failed: ${error.type} ${error.message}',
              );
              handler.next(error);
            },
          ),
        );
}
