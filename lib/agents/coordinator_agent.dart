import 'dart:async';
import 'package:flutter/foundation.dart';
import 'base_agent.dart';
import 'project_manager_agent.dart';
import 'flutter_developer_agent.dart';
import 'ui_designer_agent.dart';
import 'testing_quality_agent.dart';
import 'documentation_agent.dart';
import 'rules_compliance_agent.dart';

/// Agent Coordinator - CONTROLS ALL AGENTS
class AgentCoordinator {
  final Map<String, BaseAgent> _agents = {};
  final _messageBus = StreamController<AgentMessage>.broadcast();
  bool _isRunning = false;
  
  late final ProjectManagerAgent _pma;
  late final FlutterDeveloperAgent _fda;
  late final UiDesignerAgent _uda;
  late final TestingQualityAgent _tqa;
  late final DocumentationAgent _dda;
  late final RulesComplianceAgent _rca;
  
  AgentCoordinator() {
    _pma = ProjectManagerAgent();
    _fda = FlutterDeveloperAgent();
    _uda = UiDesignerAgent();
    _tqa = TestingQualityAgent();
    _dda = DocumentationAgent();
    _rca = RulesComplianceAgent();
    
    registerAgent(_pma);
    registerAgent(_fda);
    registerAgent(_uda);
    registerAgent(_tqa);
    registerAgent(_dda);
    registerAgent(_rca);
  }
  
  void registerAgent(BaseAgent agent) {
    _agents[agent.name] = agent;
    debugPrint('AgentCoordinator: Registered ${agent.name}');
    agent.messageStream.listen(_handleAgentMessage);
  }
  
  T getAgent<T extends BaseAgent>(String name) {
    final agent = _agents[name];
    if (agent == null) throw Exception('Agent $name not found');
    if (agent is! T) throw Exception('Agent $name is not of type $T');
    return agent;
  }
  
  List<BaseAgent> getAllAgents() => _agents.values.toList();
  
  Map<String, dynamic> getAgentStatus() {
    return {
      'total': _agents.length,
      'active': _agents.values.where((a) => a.isActive).length,
      'agents': _agents.map((name, agent) => 
        MapEntry(name, {'active': agent.isActive})),
    };
  }
  
  Future<void> startAll() async {
    debugPrint('AgentCoordinator: Starting all agents...');
    _isRunning = true;
    for (final agent in _agents.values) await agent.init();
    for (final agent in _agents.values) await agent.start();
    debugPrint('AgentCoordinator: All agents started');
    _coordinatorLoop();
  }
  
  Future<void> stopAll() async {
    debugPrint('AgentCoordinator: Stopping all agents...');
    _isRunning = false;
    for (final agent in _agents.values) await agent.stop();
    debugPrint('AgentCoordinator: All agents stopped');
  }
  
  Future<void> _coordinatorLoop() async {
    while (_isRunning) {
      await Future.delayed(const Duration(seconds: 5));
      await _checkAgentHealth();
      await _coordinateTasks();
    }
  }
  
  Future<void> _checkAgentHealth() async {
    for (final agent in _agents.values) {
      if (!agent.isActive) {
        debugPrint('AgentCoordinator: Warning - ${agent.name} is not active');
        await agent.start();
      }
    }
  }
  
  Future<void> _coordinateTasks() async {
    final complianceReport = _rca.getComplianceReport();
    final qualityReport = _tqa.getQualityReport();
    
    if ((complianceReport['violations'] as int) > 0) {
      _pma.addTask(AgentTask(
        id: 'fix_violations_${DateTime.now().millisecondsSinceEpoch}',
        assignedTo: 'FlutterDeveloperAgent',
        title: 'Fix Rule Violations',
        description: 'Fix ${complianceReport['violations']} rule violations',
        priority: TaskPriority.high,
      ));
    }
    
    if ((qualityReport['issues'] as int) > 0) {
      _pma.addTask(AgentTask(
        id: 'fix_quality_${DateTime.now().millisecondsSinceEpoch}',
        assignedTo: 'FlutterDeveloperAgent',
        title: 'Fix Quality Issues',
        description: 'Fix ${qualityReport['issues']} quality issues',
        priority: TaskPriority.high,
      ));
    }
  }
  
  void _handleAgentMessage(AgentMessage message) {
    debugPrint('AgentCoordinator: Message from ${message.from}: ${message.subject}');
    _messageBus.add(message);
    
    switch (message.type) {
      case AgentMessageType.error:
        _handleError(message);
        break;
      case AgentMessageType.status:
        _handleStatus(message);
        break;
      case AgentMessageType.request:
        _handleRequest(message);
        break;
      default:
        break;
    }
  }
  
  void _handleError(AgentMessage error) {
    debugPrint('AgentCoordinator: Error from ${error.from}: ${error.content}');
    _pma.handleMessage(error);
    
    if (error.subject.contains('Design')) _uda.handleMessage(error);
    if (error.subject.contains('Quality') || error.subject.contains('Test')) {
      _tqa.handleMessage(error);
    }
    if (error.subject.contains('Rule') || error.subject.contains('Compliance')) {
      _rca.handleMessage(error);
    }
  }
  
  void _handleStatus(AgentMessage status) {
    debugPrint('AgentCoordinator: Status update - ${status.content}');
  }
  
  void _handleRequest(AgentMessage request) {
    debugPrint('AgentCoordinator: Request from ${request.from}');
  }
  
  void sendMessageTo(String agentName, AgentMessage message) {
    final agent = _agents[agentName];
    if (agent != null) agent.handleMessage(message);
  }
  
  void broadcastMessage(AgentMessage message) {
    for (final agent in _agents.values) agent.handleMessage(message);
  }
  
  Future<void> executeTask(AgentTask task) async {
    debugPrint('AgentCoordinator: Executing task: ${task.title}');
    _pma.addTask(task);
  }
  
  Map<String, dynamic> getComplianceStatus() => _rca.getComplianceReport();
  Map<String, dynamic> getQualityStatus() => _tqa.getQualityReport();
  
  void dispose() {
    stopAll();
    _messageBus.close();
    for (final agent in _agents.values) agent.dispose();
    _agents.clear();
  }
}

// Global singleton instance
AgentCoordinator? _coordinatorInstance;
AgentCoordinator get coordinator {
  _coordinatorInstance ??= AgentCoordinator();
  return _coordinatorInstance!;
}
bool get isCoordinatorInitialized => _coordinatorInstance != null;
