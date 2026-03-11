import 'dart:async';
import 'package:flutter/foundation.dart';
import 'base_agent.dart';

/// UI/UX Designer Agent (UDA) - Designs interfaces and ensures compliance
class UiDesignerAgent extends BaseAgent {
  static const Map<String, String> designTokens = {
    'background_primary': '#121212',
    'background_secondary': '#1E1E1E',
    'primary': '#FF6200',
    'secondary': '#FF3B30',
    'accent': '#0A84FF',
    'text_primary': '#FFFFFF',
    'text_secondary': '#B3B3B3',
  };
  
  final List<String> _designViolations = [];
  
  UiDesignerAgent() : super(
    name: 'UiDesignerAgent',
    role: 'UI/UX Designer',
    responsibilities: [
      'Design interfaces',
      'Ensure design compliance',
      'Create responsive layouts',
      'Validate colors',
      'Check accessibility',
    ],
  );
  
  @override
  Future<void> init() async {
    debugPrint('$name: Initialized - Design system loaded');
  }
  
  @override
  Future<void> start() async {
    _isActive = true;
    debugPrint('$name: Started - Monitoring design compliance...');
    await execute();
  }
  
  @override
  Future<void> execute() async {
    await _checkDesignCompliance();
  }
  
  Future<void> _checkDesignCompliance() async {
    if (_designViolations.isNotEmpty) {
      debugPrint('$name: Found ${_designViolations.length} design violations');
      sendMessage(AgentMessage(
        from: name,
        type: AgentMessageType.error,
        subject: 'Design Violations Found',
        content: _designViolations.join('\n'),
      ));
    }
  }
  
  void validateColors(String filePath, List<String> colors) {
    debugPrint('$name: Validating colors in $filePath');
    for (final color in colors) {
      if (!designTokens.containsValue(color) && 
          !color.startsWith('#12') && !color.startsWith('#1E') &&
          !color.startsWith('#FF') && !color.startsWith('#0A')) {
        _designViolations.add('Non-standard color "$color" in $filePath');
      }
    }
  }
  
  void checkResponsiveLayout(String widgetCode) {
    debugPrint('$name: Checking responsive layout...');
    if (!widgetCode.contains('ScreenUtil') && 
        !widgetCode.contains('.w') && !widgetCode.contains('.h')) {
      debugPrint('$name: Warning: No responsive utilities found');
    }
  }
  
  void suggestImprovement(String suggestion) {
    sendMessage(AgentMessage(
      from: name,
      type: AgentMessageType.broadcast,
      subject: 'Design Improvement Suggestion',
      content: suggestion,
    ));
  }
  
  void clearViolations() {
    _designViolations.clear();
    debugPrint('$name: Design violations cleared');
  }
  
  @override
  void handleMessage(AgentMessage message) {
    switch (message.type) {
      case AgentMessageType.request:
        _handleRequest(message);
        break;
      case AgentMessageType.task:
        debugPrint('$name: Received design task: ${message.subject}');
        execute();
        break;
      default:
        break;
    }
  }
  
  void _handleRequest(AgentMessage message) {
    switch (message.subject) {
      case 'validate_colors':
        validateColors(
          message.metadata?['file'] ?? 'unknown',
          (message.metadata?['colors'] as List?)?.cast<String>() ?? [],
        );
        break;
      case 'check_responsive':
        checkResponsiveLayout(message.content);
        break;
      case 'suggest_improvements':
        suggestImprovement(message.content);
        break;
    }
  }
}
