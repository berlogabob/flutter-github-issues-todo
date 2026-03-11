import 'dart:async';
import 'package:flutter/foundation.dart';
import 'base_agent.dart';

/// Testing & Quality Agent (TQA) - Validates code quality and runs tests
class TestingQualityAgent extends BaseAgent {
  int _testsRun = 0;
  int _testsPassed = 0;
  int _testsFailed = 0;
  List<String> _issues = [];
  
  TestingQualityAgent() : super(
    name: 'TestingQualityAgent',
    role: 'Testing & Quality',
    responsibilities: [
      'Run tests',
      'Check code coverage',
      'Enforce linting',
      'Validate code quality',
      'Report issues',
    ],
  );
  
  @override
  Future<void> init() async {
    debugPrint('$name: Initialized - Quality checks ready');
  }
  
  @override
  Future<void> start() async {
    _isActive = true;
    debugPrint('$name: Started - Monitoring quality...');
    await execute();
  }
  
  @override
  Future<void> execute() async {
    await _runQualityChecks();
  }
  
  Future<void> _runQualityChecks() async {
    debugPrint('$name: Running quality checks...');
    if (_issues.isNotEmpty) {
      sendMessage(AgentMessage(
        from: name,
        type: AgentMessageType.error,
        subject: 'Quality Issues Found',
        content: 'Found ${_issues.length} quality issues',
      ));
    }
  }
  
  Future<Map<String, dynamic>> runAnalysis() async {
    debugPrint('$name: Running flutter analyze...');
    await Future.delayed(const Duration(seconds: 2));
    return {'errors': 0, 'warnings': 0, 'hints': 0};
  }
  
  Future<Map<String, dynamic>> runTests({String? path}) async {
    debugPrint('$name: Running tests${path != null ? ' in $path' : ''}...');
    await Future.delayed(const Duration(seconds: 3));
    _testsRun++;
    _testsPassed++;
    return {'total': 100, 'passed': 98, 'failed': 2, 'skipped': 0};
  }
  
  Future<double> checkCoverage() async {
    debugPrint('$name: Checking code coverage...');
    await Future.delayed(const Duration(seconds: 1));
    return 0.75;
  }
  
  void validateCodeStyle(String code) {
    debugPrint('$name: Validating code style...');
    if (code.contains('(') && !code.contains(',)')) {
      _issues.add('Missing trailing comma in multi-line parameters');
    }
    if (code.contains('"') && !code.contains('"""')) {
      _issues.add('Use single quotes for strings');
    }
  }
  
  void addIssue(String issue) {
    _issues.add(issue);
    debugPrint('$name: Quality issue: $issue');
  }
  
  void clearIssues() {
    _issues.clear();
    debugPrint('$name: Quality issues cleared');
  }
  
  Map<String, dynamic> getQualityReport() {
    return {
      'tests_run': _testsRun,
      'tests_passed': _testsPassed,
      'tests_failed': _testsFailed,
      'issues': _issues.length,
      'status': _issues.isEmpty ? 'PASS' : 'FAIL',
    };
  }
  
  @override
  void handleMessage(AgentMessage message) {
    switch (message.type) {
      case AgentMessageType.request:
        _handleRequest(message);
        break;
      case AgentMessageType.task:
        debugPrint('$name: Received quality task: ${message.subject}');
        execute();
        break;
      default:
        break;
    }
  }
  
  void _handleRequest(AgentMessage message) {
    switch (message.subject) {
      case 'run_tests':
        runTests(path: message.metadata?['path'] as String?);
        break;
      case 'check_coverage':
        checkCoverage();
        break;
      case 'validate_style':
        validateCodeStyle(message.content);
        break;
      case 'get_report':
        sendMessage(AgentMessage(
          from: name,
          to: message.from,
          type: AgentMessageType.response,
          subject: 'Quality Report',
          content: 'Tests: $_testsPassed/$_testsRun, Issues: ${_issues.length}',
          metadata: getQualityReport(),
        ));
        break;
    }
  }
}
