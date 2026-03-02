import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Network connectivity service
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = false;
  final _streamController = StreamController<bool>.broadcast();

  /// Get current online status
  bool get isOnline => _isOnline;

  /// Stream of online status changes
  Stream<bool> get onConnectivityChanged => _streamController.stream;

  /// Initialize network service
  Future<void> init() async {
    // Check initial status
    await _updateConnectivity();

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((_) {
      _updateConnectivity();
    });
  }

  /// Update connectivity status
  Future<void> _updateConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final wasOnline = _isOnline;

      _isOnline = results.any((result) => result != ConnectivityResult.none);

      if (wasOnline != _isOnline) {
        debugPrint('NetworkService: Online status changed: $_isOnline');
        _streamController.add(_isOnline);
      }
    } catch (e) {
      debugPrint('NetworkService: Error checking connectivity: $e');
      _isOnline = false;
    }
  }

  /// Check if network is available
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (e) {
      debugPrint('NetworkService: Connectivity check failed: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _streamController.close();
  }
}
