import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/logging.dart';

/// Connectivity Service - Monitors network connectivity with instant detection
///
/// Provides:
/// - Real-time connectivity status with instant updates
/// - Stream of connectivity changes
/// - Online/offline detection with manual fast-check
///
/// Optimized for instant cloud icon state changes (matching notification system).
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  // Current connectivity status
  bool _isOnline = false;

  // Last connectivity check time for debouncing
  DateTime? _lastCheckTime;

  // Connectivity stream subscription
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // Stream controller for connectivity changes
  final _connectivityController = StreamController<bool>.broadcast();

  /// Stream of connectivity changes
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current online status (instant access, no async)
  bool get isOnline => _isOnline;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    final metric = Logger.startMetric('initialize', 'Connectivity');
    Logger.d('Initializing ConnectivityService', context: 'Connectivity');

    try {
      // Check initial connectivity
      await _checkConnectivity();

      // Listen for connectivity changes with instant response
      _subscription = _connectivity.onConnectivityChanged.listen(
        (results) => _onConnectivityChanged(results),
        onError: (error, stackTrace) {
          Logger.e(
            'Connectivity stream error',
            error: error,
            stackTrace: stackTrace,
            context: 'Connectivity',
          );
          // On error, force offline state immediately
          _forceUpdateStatus(false);
        },
      );

      Logger.i(
        'ConnectivityService initialized, online: $_isOnline',
        context: 'Connectivity',
      );
      metric.complete(success: true);
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to initialize ConnectivityService',
        error: e,
        stackTrace: stackTrace,
        context: 'Connectivity',
      );
      metric.complete(success: false, errorMessage: e.toString());
      // Default to offline on error
      _isOnline = false;
    }
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(results);
    } catch (e, stackTrace) {
      Logger.w(
        'Failed to check connectivity',
        error: e,
        stackTrace: stackTrace,
        context: 'Connectivity',
      );
      _forceUpdateStatus(false);
    }
  }

  /// Handle connectivity changes - INSTANT update (no debounce for state changes)
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _updateConnectivityStatus(results);

    // Log immediately on state change
    if (wasOnline != _isOnline) {
      Logger.d(
        'Connectivity changed: online=$_isOnline (was: $wasOnline)',
        context: 'Connectivity',
      );
      Logger.trackJourney(
        JourneyEventType.systemAction,
        'Connectivity',
        'connectivity_changed',
        metadata: {
          'is_online': _isOnline,
          'results': results.map((r) => r.name).join(','),
        },
      );
    }
  }

  /// Update connectivity status from results and notify listeners immediately
  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    _isOnline = results.any((result) {
      return result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn;
    });

    // Notify listeners immediately on status change (no debounce for instant UI)
    if (wasOnline != _isOnline) {
      _notifyConnectivityChange();
    }
  }

  /// Force update status and notify immediately (used for error handling)
  void _forceUpdateStatus(bool newStatus) {
    if (_isOnline != newStatus) {
      _isOnline = newStatus;
      _notifyConnectivityChange();
    }
  }

  /// Notify listeners of connectivity change - instant broadcast
  void _notifyConnectivityChange() {
    // Always add to stream for instant UI updates
    try {
      _connectivityController.add(_isOnline);
    } catch (e) {
      Logger.w(
        'Failed to notify connectivity change',
        error: e,
        context: 'Connectivity',
      );
    }
  }

  /// Check if currently online - INSTANT manual check for immediate state update
  ///
  /// Call this when you need immediate connectivity verification (e.g., after user action).
  /// Returns the updated online status.
  Future<bool> checkOnlineNow() async {
    final checkStart = DateTime.now();

    // Debounce: skip if checked within last 500ms
    if (_lastCheckTime != null) {
      final elapsed = DateTime.now().difference(_lastCheckTime!).inMilliseconds;
      if (elapsed < 500) {
        Logger.d(
          'Skipping connectivity check (debounced: ${elapsed}ms)',
          context: 'Connectivity',
        );
        return _isOnline;
      }
    }

    try {
      final results = await _connectivity.checkConnectivity();
      final wasOnline = _isOnline;
      _updateConnectivityStatus(results);
      _lastCheckTime = DateTime.now();

      if (wasOnline != _isOnline) {
        Logger.d(
          'Manual connectivity check: $_isOnline (${DateTime.now().difference(checkStart).inMilliseconds}ms)',
          context: 'Connectivity',
        );
      }

      return _isOnline;
    } catch (e, stackTrace) {
      Logger.w(
        'Manual connectivity check failed',
        error: e,
        stackTrace: stackTrace,
        context: 'Connectivity',
      );
      _forceUpdateStatus(false);
      return false;
    }
  }

  /// Check if currently online (legacy method, use checkOnlineNow for instant check)
  Future<bool> checkOnline() async {
    return checkOnlineNow();
  }

  /// Force refresh connectivity state - use for instant UI updates
  ///
  /// This bypasses debouncing and forces an immediate connectivity check.
  /// Call this when you need guaranteed fresh state (e.g., cloud icon update).
  Future<bool> forceRefresh() async {
    Logger.d('Force refreshing connectivity state', context: 'Connectivity');
    _lastCheckTime = null; // Reset debounce
    return checkOnlineNow();
  }

  /// Dispose - clean up resources
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
    Logger.d('ConnectivityService disposed', context: 'Connectivity');
  }
}
