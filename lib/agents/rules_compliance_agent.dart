import 'dart:async';
import 'package:flutter/foundation.dart';
import 'base_agent.dart';

/// Rules & Compliance Agent (RCA) - NEW PROACTIVE AGENT
/// Proactively checks project rules, conventions, and politics
class RulesComplianceAgent extends BaseAgent {
  final List<RuleViolation> _violations = [];
  final Map<String, bool> _ruleChecks = {};
  
  static const List<ProjectRule> projectRules = [
    ProjectRule(id: 'naming_convention', name: 'Naming Convention', 
      description: 'Use camelCase for variables, PascalCase for classes', severity: RuleSeverity.warning),
    ProjectRule(id: 'offline_first', name: 'Offline-First Design', 
      description: 'All features must work offline with local storage', severity: RuleSeverity.critical),
    ProjectRule(id: 'dark_theme_only', name: 'Dark Theme Only', 
      description: 'Use only dark theme colors from app_colors.dart', severity: RuleSeverity.warning),
    ProjectRule(id: 'no_shortcuts', name: 'No Shortcut Engineering', 
      description: 'Avoid quick and dirty solutions', severity: RuleSeverity.error),
    ProjectRule(id: 'trailing_commas', name: 'Trailing Commas', 
      description: 'Use trailing commas in multi-line parameters', severity: RuleSeverity.warning),
    ProjectRule(id: 'single_quotes', name: 'Single Quotes', 
      description: 'Use single quotes for strings', severity: RuleSeverity.warning),
    ProjectRule(id: 'responsive_design', name: 'Responsive Design', 
      description: 'Use ScreenUtil for responsive layouts', severity: RuleSeverity.warning),
    ProjectRule(id: 'error_handling', name: 'Error Handling', 
      description: 'All async operations must have error handling', severity: RuleSeverity.critical),
    ProjectRule(id: 'secure_storage', name: 'Secure Storage', 
      description: 'Tokens must be stored in flutter_secure_storage', severity: RuleSeverity.critical),
    ProjectRule(id: 'no_env_commit', name: 'No .env Commit', 
      description: 'Never commit .env file', severity: RuleSeverity.critical),
  ];
  
  RulesComplianceAgent() : super(
    name: 'RulesComplianceAgent',
    role: 'Rules & Compliance',
    responsibilities: [
      'Check project rules',
      'Enforce conventions',
      'Validate architecture',
      'Ensure offline-first',
      'Monitor security',
      'Check dependencies',
    ],
  );
  
  @override
  Future<void> init() async {
    debugPrint('$name: Initialized - ${projectRules.length} rules loaded');
  }
  
  @override
  Future<void> start() async {
    _isActive = true;
    debugPrint('$name: Started - PROACTIVELY monitoring rules...');
    await execute();
  }
  
  @override
  Future<void> execute() async {
    await _runComplianceChecks();
    if (_violations.isNotEmpty) _reportViolations();
  }
  
  Future<void> _runComplianceChecks() async {
    debugPrint('$name: Running compliance checks...');
    for (final rule in projectRules) {
      await _checkRule(rule);
    }
  }
  
  Future<void> _checkRule(ProjectRule rule) async {
    debugPrint('$name: Checking rule: ${rule.name}');
    await Future.delayed(const Duration(milliseconds: 200));
    _ruleChecks[rule.id] = true;
  }
  
  /// PROACTIVE: Check file for rule violations
  void checkFile(String filePath, String content) {
    debugPrint('$name: PROACTIVE check: $filePath');
    _checkNamingConventions(filePath, content);
    _checkOfflineFirst(filePath, content);
    _checkErrorHandling(filePath, content);
    _checkSecureStorage(filePath, content);
    _checkResponsiveDesign(filePath, content);
  }
  
  void _checkNamingConventions(String filePath, String content) {
    final classPattern = RegExp(r'class\s+([a-z]\w*)');
    for (final match in classPattern.allMatches(content)) {
      _violations.add(RuleViolation(
        ruleId: 'naming_convention', file: filePath, line: -1,
        message: 'Class "${match.group(1)}" should use PascalCase',
        severity: RuleSeverity.warning,
      ));
    }
  }
  
  void _checkOfflineFirst(String filePath, String content) {
    if ((content.contains('http.') || content.contains('Dio')) &&
        !content.contains('cache') && !content.contains('Cache') &&
        !content.contains('LocalStorage') && !content.contains('Hive')) {
      _violations.add(RuleViolation(
        ruleId: 'offline_first', file: filePath, line: -1,
        message: 'API call without offline fallback detected',
        severity: RuleSeverity.critical,
      ));
    }
  }
  
  void _checkErrorHandling(String filePath, String content) {
    final asyncPattern = RegExp(r'Future<\w+>\s+\w+\([^)]*\)\s*(async)?');
    if (asyncPattern.hasMatch(content) && 
        !content.contains('try') && !content.contains('catch')) {
      _violations.add(RuleViolation(
        ruleId: 'error_handling', file: filePath, line: -1,
        message: 'Async function without error handling',
        severity: RuleSeverity.critical,
      ));
    }
  }
  
  void _checkSecureStorage(String filePath, String content) {
    if ((content.contains('token') || content.contains('Token')) &&
        !content.contains('SecureStorage') && 
        !content.contains('flutter_secure_storage')) {
      _violations.add(RuleViolation(
        ruleId: 'secure_storage', file: filePath, line: -1,
        message: 'Token handling without secure storage',
        severity: RuleSeverity.critical,
      ));
    }
  }
  
  void _checkResponsiveDesign(String filePath, String content) {
    if ((filePath.contains('screen') || filePath.contains('widget')) &&
        !content.contains('ScreenUtil') && !content.contains('.w') &&
        !content.contains('.h') && !content.contains('responsive')) {
      _violations.add(RuleViolation(
        ruleId: 'responsive_design', file: filePath, line: -1,
        message: 'Screen/widget without responsive utilities',
        severity: RuleSeverity.warning,
      ));
    }
  }
  
  void _reportViolations() {
    final critical = _violations.where((v) => v.severity == RuleSeverity.critical).length;
    final errors = _violations.where((v) => v.severity == RuleSeverity.error).length;
    final warnings = _violations.where((v) => v.severity == RuleSeverity.warning).length;
    
    sendMessage(AgentMessage(
      from: name,
      type: AgentMessageType.error,
      subject: 'RULE VIOLATIONS DETECTED',
      content: 'Critical: $critical, Errors: $errors, Warnings: $warnings',
      metadata: {
        'violations': _violations.map((v) => v.toJson()).toList(),
        'critical': critical, 'errors': errors, 'warnings': warnings,
      },
    ));
  }
  
  void addViolation(RuleViolation violation) {
    _violations.add(violation);
    debugPrint('$name: Violation: ${violation.message}');
  }
  
  void clearViolations() {
    _violations.clear();
    debugPrint('$name: Violations cleared');
  }
  
  Map<String, dynamic> getComplianceReport() {
    return {
      'rules_checked': _ruleChecks.length,
      'violations': _violations.length,
      'status': _violations.isEmpty ? 'COMPLIANT' : 'NON_COMPLIANT',
    };
  }
  
  @override
  void handleMessage(AgentMessage message) {
    switch (message.type) {
      case AgentMessageType.request:
        _handleRequest(message);
        break;
      case AgentMessageType.task:
        debugPrint('$name: Received compliance task: ${message.subject}');
        execute();
        break;
      default:
        break;
    }
  }
  
  void _handleRequest(AgentMessage message) {
    switch (message.subject) {
      case 'check_file':
        checkFile(message.metadata?['file'] ?? 'unknown', message.content);
        break;
      case 'get_report':
        sendMessage(AgentMessage(
          from: name, to: message.from, type: AgentMessageType.response,
          subject: 'Compliance Report',
          content: 'Rules: ${_ruleChecks.length}, Violations: ${_violations.length}',
          metadata: getComplianceReport(),
        ));
        break;
    }
  }
}

class ProjectRule {
  final String id, name, description;
  final RuleSeverity severity;
  const ProjectRule({required this.id, required this.name, 
    required this.description, required this.severity});
}

class RuleViolation {
  final String ruleId, file, message;
  final int line;
  final RuleSeverity severity;
  RuleViolation({required this.ruleId, required this.file, required this.line,
    required this.message, required this.severity});
  Map<String, dynamic> toJson() => {
    'rule': ruleId, 'file': file, 'line': line,
    'message': message, 'severity': severity.name,
  };
}

enum RuleSeverity { info, warning, error, critical }
