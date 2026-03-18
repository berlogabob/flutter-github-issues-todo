# 🚀 GitDoIt Architectural Redesign Plan

**Project:** GitDoIt v0.6.0 - Complete Architectural Overhaul  
**Date:** March 18, 2026  
**Current Version:** 0.5.0+126  
**Target Version:** 0.6.0+200  
**Sprint Duration:** 6 weeks (3 sprints × 2 weeks)

---

## 📊 Executive Summary

### Current State:
- **Health Score:** 31/100 🔴
- **Root Causes:** 7 architectural flaws
- **Critical Issues:** 23
- **Tail Effects:** 47+ user-visible failures

### Target State:
- **Health Score:** 90+/100 ✅
- **Root Causes:** 0 (all eliminated)
- **Critical Issues:** 0
- **Tail Effects:** 0

### Business Impact:
- **Data Loss Prevention:** 100% offline reliability
- **User Retention:** Eliminate frustration-driven uninstalls
- **Development Velocity:** 3x faster with testable architecture
- **App Store Rating:** Target 4.5+ stars (from current issues)

---

## 🎯 Design Principles (New Architecture)

### 1. **Explicit Dependencies**
- ❌ NO hardcoded dependencies
- ✅ ALL dependencies injected via constructors
- ✅ Service locator pattern for global access

### 2. **Lifecycle Management**
- ❌ NO resource leaks
- ✅ ALL services implement `Disposable`
- ✅ Widgets dispose services in `dispose()`

### 3. **Async/Sync Boundaries**
- ❌ NO async operations in sync context
- ✅ ALL async operations properly awaited
- ✅ Factory constructors for async initialization

### 4. **Validation Layers**
- ❌ NO silent failures
- ✅ ALL input validated
- ✅ FAIL FAST with clear errors

### 5. **Error Classification**
- ❌ NO generic error messages
- ✅ ALL errors classified by severity
- ✅ Actionable recovery steps provided

### 6. **Circuit Breaker Pattern**
- ❌ NO infinite retry loops
- ✅ GLOBAL failure tracking
- ✅ COORDINATED backoff

### 7. **Offline-First (Proper)**
- ❌ NO race conditions on init
- ✅ DETERMINISTIC initialization order
- ✅ FALLBACK storage when primary fails

---

## 🏗️ New Architecture Overview

### Layer 1: Core Services (Foundation)
```
┌─────────────────────────────────────────────────┐
│           Service Container (Singleton)          │
│  - Manages all service lifecycles               │
│  - Dependency injection registry                 │
│  - Initialization coordination                   │
└─────────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────┐
│          Storage Layer (Abstract)               │
│  - IStorage interface                           │
│  - HiveStorage (primary)                        │
│  - MemoryStorage (fallback)                     │
│  - SecureStorage (tokens)                       │
└─────────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────┐
│          Network Layer (Abstract)               │
│  - INetworkService interface                    │
│  - NetworkService (implementation)              │
│  - CircuitBreaker (protection)                  │
│  - RetryPolicy (with backoff)                   │
└─────────────────────────────────────────────────┘
```

### Layer 2: Business Services
```
┌─────────────────────────────────────────────────┐
│           GitHub API Service                    │
│  - REST API client                              │
│  - GraphQL API client                           │
│  - Response caching                             │
│  - Rate limit handling                          │
└─────────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────┐
│           Sync Service                          │
│  - Two-way sync engine                          │
│  - Conflict detection/resolution                │
│  - Transaction support                          │
│  - Progress tracking                            │
└─────────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────┐
│           Issue Service                         │
│  - CRUD operations                              │
│  - Optimistic updates                           │
│  - Rollback support                             │
└─────────────────────────────────────────────────┘
```

### Layer 3: State Management
```
┌─────────────────────────────────────────────────┐
│           Riverpod Providers                    │
│  - Async notifiers                              │
│  - State holders                                │
│  - UI bindings                                  │
└─────────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────┐
│           UI Widgets                            │
│  - Consumer widgets                             │
│  - State listeners                              │
│  - Error boundaries                             │
└─────────────────────────────────────────────────┘
```

---

## 📋 Sprint Breakdown

### **Sprint 1: Foundation (Weeks 1-2)**
**Goal:** Eliminate Root Causes #1, #2, #3

#### Week 1: Service Container & Dependency Injection
- [ ] **Task 1.1:** Create ServiceContainer class
- [ ] **Task 1.2:** Implement service registry
- [ ] **Task 1.3:** Create Disposable interface
- [ ] **Task 1.4:** Refactor SecureStorageService
- [ ] **Task 1.5:** Refactor NetworkService
- [ ] **Task 1.6:** Update main.dart initialization

#### Week 2: Lifecycle Management
- [ ] **Task 2.1:** Implement dispose() for all services
- [ ] **Task 2.2:** Update widgets to dispose services
- [ ] **Task 2.3:** Add lifecycle tests
- [ ] **Task 2.4:** Refactor CacheService (async factory)
- [ ] **Task 2.5:** Refactor PendingOperationsService
- [ ] **Task 2.6:** Integration tests

**Deliverables:**
- ✅ ServiceContainer with DI
- ✅ All services implement Disposable
- ✅ No resource leaks
- ✅ Testable service mocks

---

### **Sprint 2: Reliability (Weeks 3-4)**
**Goal:** Eliminate Root Causes #4, #5, #6

#### Week 3: Async/Sync Boundaries & Validation
- [ ] **Task 3.1:** Make all cache access async
- [ ] **Task 3.2:** Add validation to markdown parser
- [ ] **Task 3.3:** Implement YAML validation
- [ ] **Task 3.4:** Add filename validation
- [ ] **Task 3.5:** Create ValidationResult type
- [ ] **Task 3.6:** Update error handling

#### Week 4: Circuit Breaker & Retry
- [ ] **Task 4.1:** Implement CircuitBreaker class
- [ ] **Task 4.2:** Add global failure tracking
- [ ] **Task 4.3:** Update RetryHelper with circuit breaker
- [ ] **Task 4.4:** Add rate limit detection
- [ ] **Task 4.5:** Coordinated backoff
- [ ] **Task 4.6:** Circuit breaker tests

**Deliverables:**
- ✅ Async-only cache access
- ✅ Validated input parsing
- ✅ Circuit breaker pattern
- ✅ Rate limit protection

---

### **Sprint 3: Error Handling & Polish (Weeks 5-6)**
**Goal:** Eliminate Root Cause #7, Final Testing

#### Week 5: Error Classification
- [ ] **Task 5.1:** Create ErrorSeverity enum
- [ ] **Task 5.2:** Implement AppError class
- [ ] **Task 5.3:** Create error classifier
- [ ] **Task 5.4:** Add recovery actions
- [ ] **Task 5.5:** Update UI error displays
- [ ] **Task 5.6:** User notification system

#### Week 6: Integration Testing & Deployment
- [ ] **Task 6.1:** Chaos engineering tests
- [ ] **Task 6.2:** Failure chain tests
- [ ] **Task 6.3:** Performance benchmarks
- [ ] **Task 6.4:** User acceptance testing
- [ ] **Task 6.5:** Documentation update
- [ ] **Task 6.6:** Production deployment

**Deliverables:**
- ✅ Classified error handling
- ✅ Actionable error messages
- ✅ Comprehensive test suite
- ✅ Production-ready release

---

## 🔧 Detailed Task Specifications

### **Task 1.1: Create ServiceContainer Class**

**File:** `lib/core/service_container.dart`

```dart
import 'package:flutter/foundation.dart';

/// Service Container - Central dependency injection registry
///
/// Manages service lifecycles, initialization order, and disposal.
/// All services are registered here and accessed through the container.
///
/// Usage:
/// ```dart
/// // Initialize in main.dart
/// final container = ServiceContainer();
/// await container.initialize();
///
/// // Access services
/// final syncService = container.get<SyncService>();
/// final cacheService = container.get<CacheService>();
///
/// // Cleanup on exit
/// await container.dispose();
/// ```
class ServiceContainer {
  final Map<Type, dynamic> _services = {};
  final Map<Type, List<dynamic>> _dependencies = {};
  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Register a service (must be called before initialize)
  void register<T>(T service, {List<Type>? dependencies}) {
    if (_isInitialized) {
      throw StateError('Cannot register services after initialization');
    }
    _services[T] = service;
    if (dependencies != null) {
      _dependencies[T] = dependencies;
    }
  }

  /// Get a service (throws if not found or not initialized)
  T get<T>() {
    if (!_isInitialized) {
      throw StateError('ServiceContainer not initialized');
    }
    final service = _services[T];
    if (service == null) {
      throw StateError('Service ${T.toString()} not registered');
    }
    return service as T;
  }

  /// Initialize all services in dependency order
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      // Wait for initialization to complete
      while (_isInitializing && !_isInitialized) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _isInitializing = true;

    try {
      // Topological sort for dependency order
      final ordered = _topologicalSort();

      // Initialize in order
      for (final type in ordered) {
        final service = _services[type];
        if (service is Initializable) {
          debugPrint('Initializing ${type.toString()}...');
          await service.init();
        }
      }

      _isInitialized = true;
      debugPrint('ServiceContainer: All services initialized');
    } catch (e, stackTrace) {
      debugPrint('ServiceContainer: Initialization failed: $e');
      debugPrint('Stack: $stackTrace');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Dispose all services in reverse order
  Future<void> dispose() async {
    if (!_isInitialized) return;

    final ordered = _topologicalSort();

    // Dispose in reverse order
    for (final type in ordered.reversed) {
      final service = _services[type];
      if (service is Disposable) {
        debugPrint('Disposing ${type.toString()}...');
        await service.dispose();
      }
    }

    _services.clear();
    _isInitialized = false;
    debugPrint('ServiceContainer: All services disposed');
  }

  /// Topological sort for dependency ordering
  List<Type> _topologicalSort() {
    // Simple implementation - can be optimized
    final result = <Type>[];
    final visited = <Type>{};

    void visit(Type type) {
      if (visited.contains(type)) return;
      visited.add(type);

      final deps = _dependencies[type] ?? [];
      for (final dep in deps) {
        visit(dep);
      }

      result.add(type);
    }

    for (final type in _services.keys) {
      visit(type);
    }

    return result;
  }

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Get all registered service types
  List<Type> get registeredServices => _services.keys.toList();
}

/// Interface for services that need initialization
abstract class Initializable {
  Future<void> init();
}

/// Interface for services that need disposal
abstract class Disposable {
  Future<void> dispose();
}
```

**Tests:** `test/core/service_container_test.dart`

---

### **Task 1.4: Refactor SecureStorageService**

**File:** `lib/services/secure_storage_service.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/service_container.dart';

/// SecureStorageService - Secure storage for tokens and sensitive data
///
/// REFACTORED: Now implements Initializable and Disposable
/// Uses factory constructor for proper async initialization
class SecureStorageService implements Initializable, Disposable {
  final FlutterSecureStorage _storage;
  bool _isInitialized = false;

  SecureStorageService._(this._storage);

  /// Factory constructor for async initialization
  static Future<SecureStorageService> create() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(),
      iOptions: IOSOptions(),
    );
    final service = SecureStorageService._(storage);
    await service.init();
    return service;
  }

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Test storage availability
      await _storage.read(key: '__test__');
      _isInitialized = true;
      debugPrint('SecureStorageService: Initialized');
    } catch (e, stackTrace) {
      debugPrint('SecureStorageService: Init failed: $e');
      debugPrint('Stack: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    // FlutterSecureStorage doesn't need explicit disposal
    _isInitialized = false;
    debugPrint('SecureStorageService: Disposed');
  }

  // ... existing methods with error handling ...
}
```

---

### **Task 3.2: Add Validation to Markdown Parser**

**File:** `lib/services/local_storage_service.dart`

```dart
/// ValidationResult for parsing operations
class ParseResult<T> {
  final T? value;
  final List<String> errors;
  final bool success;

  ParseResult._({this.value, required this.errors})
      : success = errors.isEmpty;

  factory ParseResult.success(T value) {
    return ParseResult._(value: value, errors: []);
  }

  factory ParseResult.failure(List<String> errors) {
    return ParseResult._(errors: errors);
  }
}

/// Parse markdown file with validation
ParseResult<IssueItem> _parseMarkdownToIssue(
  String filePath,
  String content,
) {
  final errors = <String>[];

  // Validate filename format
  final fileName = filePath.split('/').last;
  final idMatch = RegExp(r'^(local_\d+)_').firstMatch(fileName);
  if (idMatch == null) {
    errors.add('Invalid filename format: $fileName (expected: local_<timestamp>_*)');
    return ParseResult.failure(errors); // ✅ FAIL FAST
  }
  final id = idMatch.group(1)!;

  // Validate YAML frontmatter
  final frontmatterMatch = RegExp(
    r'^---\s*\n(.*?)\n---\s*\n',
    dotAll: true,
    multiLine: true,
  ).firstMatch(content);

  if (frontmatterMatch == null) {
    errors.add('Missing or malformed YAML frontmatter in: $fileName');
    return ParseResult.failure(errors); // ✅ REQUIRE VALID FORMAT
  }

  final frontmatter = frontmatterMatch.group(1) ?? '';

  // Parse fields with validation
  final title = _parseYamlField(frontmatter, 'title');
  if (title == null || title.isEmpty) {
    errors.add('Missing required field: title');
  }

  final statusStr = _parseYamlField(frontmatter, 'status');
  final status = statusStr == 'closed' ? ItemStatus.closed : ItemStatus.open;

  // Date parsing with error collection
  DateTime? updatedAt;
  final dateStr = _parseYamlField(frontmatter, 'created');
  if (dateStr != null) {
    try {
      updatedAt = DateTime.parse(dateStr);
    } catch (e) {
      errors.add('Invalid date format: $dateStr (expected: ISO 8601)');
      updatedAt = DateTime.now(); // Fallback but log error
    }
  }

  // If errors, return failure
  if (errors.isNotEmpty) {
    return ParseResult.failure(errors);
  }

  // Success
  final issue = IssueItem(
    id: id,
    title: title!,
    bodyMarkdown: content.substring(frontmatterMatch.end).trim(),
    labels: _parseYamlList(frontmatter, 'labels'),
    status: status,
    updatedAt: updatedAt,
    isLocalOnly: true,
  );

  return ParseResult.success(issue);
}
```

---

### **Task 4.1: Implement CircuitBreaker Class**

**File:** `lib/core/circuit_breaker.dart`

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Circuit Breaker State
enum CircuitState {
  closed,    // Normal operation
  open,      // Failing, reject calls
  halfOpen,  // Testing if service recovered
}

/// Circuit Breaker - Prevents cascade failures
///
/// Tracks failures across all operations and opens circuit
/// when threshold is exceeded. Prevents retry storms.
///
/// Usage:
/// ```dart
/// final circuit = CircuitBreaker(
///   failureThreshold: 5,
///   resetTimeout: Duration(minutes: 5),
/// );
///
/// try {
///   await circuit.execute(() => api.call());
/// } on CircuitOpenException {
///   // Service unavailable, use fallback
/// }
/// ```
class CircuitBreaker {
  final int failureThreshold;
  final Duration resetTimeout;
  final Duration halfOpenMaxCalls;

  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;
  DateTime? _lastStateChangeTime;
  int _halfOpenCalls = 0;

  final _streamController = StreamController<CircuitState>.broadcast();

  CircuitBreaker({
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(minutes: 5),
    this.halfOpenMaxCalls = 3,
  });

  /// Execute operation with circuit breaker protection
  Future<T> execute<T>(Future<T> Function() operation) async {
    // Check circuit state
    if (_state == CircuitState.open) {
      // Check if reset timeout has passed
      if (_shouldAttemptReset()) {
        _transitionTo(CircuitState.halfOpen);
      } else {
        throw CircuitOpenException(
          'Circuit breaker is open',
          retryAfter: _getRetryAfter(),
        );
      }
    }

    // Limit calls in half-open state
    if (_state == CircuitState.halfOpen) {
      if (_halfOpenCalls >= halfOpenMaxCalls) {
        throw CircuitOpenException(
          'Circuit breaker half-open: max calls exceeded',
          retryAfter: Duration(seconds: 10),
        );
      }
      _halfOpenCalls++;
    }

    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  void _onSuccess() {
    _successCount++;
    _failureCount = 0; // Reset on success

    if (_state == CircuitState.halfOpen) {
      // Success in half-open state → close circuit
      _transitionTo(CircuitState.closed);
    }
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_state == CircuitState.halfOpen) {
      // Failure in half-open state → open circuit again
      _transitionTo(CircuitState.open);
    } else if (_failureCount >= failureThreshold) {
      // Threshold exceeded → open circuit
      _transitionTo(CircuitState.open);
    }
  }

  bool _shouldAttemptReset() {
    if (_lastFailureTime == null) return true;
    return DateTime.now()
        .difference(_lastFailureTime!) >=
        resetTimeout;
  }

  Duration _getRetryAfter() {
    if (_lastFailureTime == null) return Duration.zero;
    final elapsed = DateTime.now().difference(_lastFailureTime!);
    return resetTimeout - elapsed;
  }

  void _transitionTo(CircuitState newState) {
    _state = newState;
    _lastStateChangeTime = DateTime.now();
    _halfOpenCalls = 0;

    debugPrint(
      'CircuitBreaker: State changed to $newState '
      '(failures: $_failureCount, successes: $_successCount)',
    );

    _streamController.add(newState);
  }

  /// Get current state
  CircuitState get state => _state;

  /// Get failure count
  int get failureCount => _failureCount;

  /// Get success count
  int get successCount => _successCount;

  /// Stream of state changes
  Stream<CircuitState> get onStateChange => _streamController.stream;

  /// Get statistics
  Map<String, dynamic> getStats() {
    return {
      'state': _state.name,
      'failureCount': _failureCount,
      'successCount': _successCount,
      'lastFailureTime': _lastFailureTime,
      'lastStateChangeTime': _lastStateChangeTime,
    };
  }

  /// Reset circuit breaker
  void reset() {
    _transitionTo(CircuitState.closed);
    _failureCount = 0;
    _successCount = 0;
    _lastFailureTime = null;
  }

  void dispose() {
    _streamController.close();
  }
}

/// Exception thrown when circuit breaker is open
class CircuitOpenException implements Exception {
  final String message;
  final Duration? retryAfter;

  CircuitOpenException(this.message, {this.retryAfter});

  @override
  String toString() => 'CircuitOpenException: $message';
}
```

---

## 📊 Success Metrics

### Sprint 1 Metrics:
- [ ] All 7 services implement `Disposable`
- [ ] ServiceContainer initialized in main.dart
- [ ] Zero resource leaks (verified by tests)
- [ ] 100% service mock coverage

### Sprint 2 Metrics:
- [ ] 100% async operations properly awaited
- [ ] All parsers return `ParseResult` with validation
- [ ] Circuit breaker protects all API calls
- [ ] Rate limit failures reduced to 0

### Sprint 3 Metrics:
- [ ] All errors classified by severity
- [ ] User sees actionable error messages
- [ ] 95% test coverage
- [ ] Health score ≥ 90/100

---

## 🎯 Agent Team Assignments

### Project Manager Agent (PMA):
- [ ] Create sprint tasks in project board
- [ ] Assign tasks to agents
- [ ] Track sprint progress daily
- [ ] Coordinate between agents

### Flutter Developer Agent (FDA):
- [ ] Implement ServiceContainer (Task 1.1)
- [ ] Refactor all services (Tasks 1.4-1.6, 2.1-2.6)
- [ ] Implement CircuitBreaker (Task 4.1)
- [ ] Update all async/sync boundaries (Tasks 3.1-3.6)

### UI/UX Designer Agent (UDA):
- [ ] Design error message UI (Task 5.5)
- [ ] Create error state illustrations
- [ ] Update loading states
- [ ] Design circuit breaker notifications

### Testing & Quality Agent (TQA):
- [ ] Write service container tests (Task 1.1)
- [ ] Write lifecycle tests (Task 2.3)
- [ ] Write validation tests (Tasks 3.2-3.5)
- [ ] Write circuit breaker tests (Task 4.6)
- [ ] Chaos engineering tests (Task 6.1)

### Documentation Agent (DDA):
- [ ] Update architecture docs
- [ ] Document new patterns
- [ ] Update API documentation
- [ ] Create migration guide
- [ ] Update CHANGELOG.md

### Rules & Compliance Agent (RCA):
- [ ] Enforce new architecture patterns
- [ ] Validate dependency injection usage
- [ ] Check lifecycle management compliance
- [ ] Monitor error handling patterns
- [ ] Prevent regression to old patterns

---

## 🚀 Execution Timeline

### Week 1 (Mar 18-24):
- ServiceContainer implementation
- Initial service refactoring
- Basic tests

### Week 2 (Mar 25-31):
- Complete service refactoring
- Lifecycle management
- Integration tests

### Week 3 (Apr 1-7):
- Async/sync boundary fixes
- Validation layers
- Parser updates

### Week 4 (Apr 8-14):
- Circuit breaker implementation
- Retry policy updates
- Rate limit protection

### Week 5 (Apr 15-21):
- Error classification
- UI updates
- User notifications

### Week 6 (Apr 22-28):
- Final testing
- Performance benchmarks
- Production deployment

---

## ⚠️ Risk Mitigation

### Risk 1: Breaking Changes
**Mitigation:**
- Maintain backward compatibility during transition
- Feature flag new architecture
- Gradual rollout

### Risk 2: Data Migration
**Mitigation:**
- Backward-compatible storage format
- Migration tests
- Rollback plan

### Risk 3: Performance Regression
**Mitigation:**
- Performance benchmarks before/after
- Load testing
- Optimization sprint if needed

### Risk 4: Scope Creep
**Mitigation:**
- Strict sprint boundaries
- Priority-based task selection
- Defer non-critical improvements

---

## ✅ Definition of Done

### For Each Task:
- [ ] Implementation complete
- [ ] Unit tests written and passing
- [ ] Integration tests passing
- [ ] Code reviewed by TQA
- [ ] RCA compliance verified
- [ ] Documentation updated

### For Each Sprint:
- [ ] All tasks complete
- [ ] Sprint goals achieved
- [ ] Metrics met
- [ ] Demo prepared
- [ ] Retrospective conducted

### For Project:
- [ ] All sprints complete
- [ ] Health score ≥ 90/100
- [ ] Zero critical issues
- [ ] User acceptance testing passed
- [ ] Production deployment successful

---

## 📞 Communication Plan

### Daily:
- Agent standup (automated status updates)
- Progress tracking in project board

### Weekly:
- Sprint review (Friday)
- Sprint planning (Monday)
- Retrospective (bi-weekly)

### Milestones:
- Sprint 1 demo (Mar 31)
- Sprint 2 demo (Apr 14)
- Final demo (Apr 28)
- Production release (May 1)

---

**Ready to execute. Awaiting agent team confirmation.**

---

**Created by:** Deep Architecture Analysis  
**Date:** March 18, 2026  
**Version:** 1.0  
**Status:** Ready for Execution
