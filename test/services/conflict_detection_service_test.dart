import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/services/conflict_detection_service.dart';
import 'package:gitdoit/models/issue_item.dart';
import 'package:gitdoit/models/item.dart';

void main() {
  group('ConflictDetectionService', () {
    late ConflictDetectionService service;

    setUp(() {
      service = ConflictDetectionService();
    });

    tearDown(() {
      service.clearConflicts();
    });

    test('should create singleton instance', () {
      final service2 = ConflictDetectionService();
      expect(identical(service, service2), isTrue);
    });

    test('should detect no conflicts for empty lists', () {
      final conflicts = service.detectConflicts(
        localIssues: [],
        remoteIssues: [],
      );

      expect(conflicts, isEmpty);
      expect(service.getConflictCount(), equals(0));
    });

    test('should detect no conflicts when local issue has no number', () {
      final localIssue = IssueItem(
        id: 'local_123',
        title: 'Local Issue',
        isLocalOnly: true,
      );

      final remoteIssue = IssueItem(
        id: 'remote_456',
        title: 'Remote Issue',
        number: 1,
      );

      final conflicts = service.detectConflicts(
        localIssues: [localIssue],
        remoteIssues: [remoteIssue],
      );

      expect(conflicts, isEmpty);
    });

    test('should detect no conflicts when local issue not modified', () {
      final localIssue = IssueItem(
        id: 'issue_123',
        title: 'Same Title',
        number: 1,
        isLocalOnly: false,
        localUpdatedAt: null, // Not modified locally
      );

      final remoteIssue = IssueItem(
        id: 'issue_456',
        title: 'Different Title',
        number: 1,
        updatedAt: DateTime.now(),
      );

      final conflicts = service.detectConflicts(
        localIssues: [localIssue],
        remoteIssues: [remoteIssue],
      );

      expect(conflicts, isEmpty);
    });

    test('should detect conflict when local modified after remote', () {
      final remoteTime = DateTime.now().subtract(const Duration(hours: 1));
      final localTime = DateTime.now();

      final localIssue = IssueItem(
        id: 'issue_123',
        title: 'Local Title',
        number: 1,
        isLocalOnly: false,
        localUpdatedAt: localTime,
      );

      final remoteIssue = IssueItem(
        id: 'issue_456',
        title: 'Remote Title',
        number: 1,
        updatedAt: remoteTime,
      );

      final conflicts = service.detectConflicts(
        localIssues: [localIssue],
        remoteIssues: [remoteIssue],
      );

      expect(conflicts, isNotEmpty);
      expect(conflicts.first.issueNumber, equals(1));
      expect(service.getConflictCount(), equals(1));
    });

    test('should detect title conflict', () {
      final remoteTime = DateTime.now().subtract(const Duration(hours: 1));
      final localTime = DateTime.now();

      final localIssue = IssueItem(
        id: 'issue_123',
        title: 'Local Title',
        number: 1,
        localUpdatedAt: localTime,
      );

      final remoteIssue = IssueItem(
        id: 'issue_456',
        title: 'Remote Title',
        number: 1,
        updatedAt: remoteTime,
      );

      final conflicts = service.detectConflicts(
        localIssues: [localIssue],
        remoteIssues: [remoteIssue],
      );

      expect(conflicts, isNotEmpty);
      expect(conflicts.first.hasTitleConflict, isTrue);
    });

    test('should detect labels conflict', () {
      final remoteTime = DateTime.now().subtract(const Duration(hours: 1));
      final localTime = DateTime.now();

      final localIssue = IssueItem(
        id: 'issue_123',
        title: 'Same Title',
        number: 1,
        labels: ['bug', 'enhancement'],
        localUpdatedAt: localTime,
      );

      final remoteIssue = IssueItem(
        id: 'issue_456',
        title: 'Same Title',
        number: 1,
        labels: ['bug'],
        updatedAt: remoteTime,
      );

      final conflicts = service.detectConflicts(
        localIssues: [localIssue],
        remoteIssues: [remoteIssue],
      );

      expect(conflicts, isNotEmpty);
      expect(conflicts.first.hasLabelsConflict, isTrue);
    });

    test('should detect status conflict', () {
      final remoteTime = DateTime.now().subtract(const Duration(hours: 1));
      final localTime = DateTime.now();

      final localIssue = IssueItem(
        id: 'issue_123',
        title: 'Same Title',
        number: 1,
        status: ItemStatus.closed,
        localUpdatedAt: localTime,
      );

      final remoteIssue = IssueItem(
        id: 'issue_456',
        title: 'Same Title',
        number: 1,
        status: ItemStatus.open,
        updatedAt: remoteTime,
      );

      final conflicts = service.detectConflicts(
        localIssues: [localIssue],
        remoteIssues: [remoteIssue],
      );

      expect(conflicts, isNotEmpty);
      expect(conflicts.first.hasStatusConflict, isTrue);
    });

    test('should detect multiple conflicts', () {
      final remoteTime = DateTime.now().subtract(const Duration(hours: 1));
      final localTime = DateTime.now();

      final localIssue = IssueItem(
        id: 'issue_123',
        title: 'Local Title',
        number: 1,
        status: ItemStatus.closed,
        labels: ['bug'],
        localUpdatedAt: localTime,
      );

      final remoteIssue = IssueItem(
        id: 'issue_456',
        title: 'Remote Title',
        number: 1,
        status: ItemStatus.open,
        labels: ['enhancement'],
        updatedAt: remoteTime,
      );

      final conflicts = service.detectConflicts(
        localIssues: [localIssue],
        remoteIssues: [remoteIssue],
      );

      expect(conflicts, isNotEmpty);
      expect(conflicts.first.hasTitleConflict, isTrue);
      expect(conflicts.first.hasStatusConflict, isTrue);
      expect(conflicts.first.hasLabelsConflict, isTrue);
    });

    test('should clear conflicts', () {
      final localIssue = IssueItem(
        id: 'issue_123',
        title: 'Local Title',
        number: 1,
        localUpdatedAt: DateTime.now(),
      );

      final remoteIssue = IssueItem(
        id: 'issue_456',
        title: 'Remote Title',
        number: 1,
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      service.detectConflicts(
        localIssues: [localIssue],
        remoteIssues: [remoteIssue],
      );

      expect(service.getConflictCount(), greaterThan(0));

      service.clearConflicts();

      expect(service.getConflictCount(), equals(0));
      expect(service.hasConflicts(), isFalse);
    });

    test('should return unmodifiable conflicts list', () {
      final localIssue = IssueItem(
        id: 'issue_123',
        title: 'Local Title',
        number: 1,
        localUpdatedAt: DateTime.now(),
      );

      final remoteIssue = IssueItem(
        id: 'issue_456',
        title: 'Remote Title',
        number: 1,
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final conflicts = service.detectConflicts(
        localIssues: [localIssue],
        remoteIssues: [remoteIssue],
      );

      expect(
        () => conflicts.add(
          IssueConflict(
            issueId: 'test',
            issueNumber: 999,
            localIssue: localIssue,
            remoteIssue: remoteIssue,
            conflictingFields: [],
            detectedAt: DateTime.now(),
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
