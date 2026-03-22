import 'dart:async';
import 'package:flutter/foundation.dart';
import 'base_agent.dart';
import 'mr_planner.dart';
import 'mr_developer.dart';
import 'mr_designer.dart';
import 'mr_tester.dart';
import 'mr_logger.dart';
import 'mr_compliance.dart';

/// Agent Coordinator - Central control system for all agents.
///
/// The MrCoordinator is the central controller that:
/// - Registers and manages all agents
/// - Facilitates inter-agent communication through a message bus
/// - Monitors agent health and restarts inactive agents
/// - Coordinates parallel execution of tasks
/// - Provides centralized control and status reporting
/// - Routes messages between agents
///
/// Agents Managed:
/// - [MrPlanner] - Project management and task assignment
/// - [MrDeveloper] - Code implementation and feature development
/// - [MrDesigner] - UI/UX design and compliance
/// - [MrTester] - Testing and quality assurance
/// - [MrLogger] - Documentation and deployment
/// - [MrCompliance] - Rules and compliance monitoring
///
/// Usage:
/// ```dart
/// final coordinator = get coordinator; // Singleton access
/// await coordinator.startAll();
///
/// // Check status
/// print(coordinator.getAgentStatus());
/// print(coordinator.getComplianceStatus());
///
/// await coordinator.stopAll();
/// ```
class MrCoordinator {
  final Map<String, BaseAgent> _agents = {};
  final _messageBus = StreamController<AgentMessage>.broadcast();
  bool _isRunning = false;
  
  late final MrPlanner _pma;
  late final MrDeveloper _fda;
  late final MrDesigner _uda;
  late final MrTester _tqa;
  late final MrLogger _dda;
  late final MrCompliance _rca;
  
  MrCoordinator() {
    _pma = MrPlanner();
    _fda = MrDeveloper();
    _uda = MrDesigner();
    _tqa = MrTester();
    _dda = MrLogger();
    _rca = MrCompliance();
    
    registerAgent(_pma);
    registerAgent(_fda);
    registerAgent(_uda);
    registerAgent(_tqa);
    registerAgent(_dda);
    registerAgent(_rca);
  }
  
  void registerAgent(BaseAgent agent) {
    _agents[agent.name] = agent;
    debugPrint('MrCoordinator: Registered ${agent.name}');
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
    debugPrint('MrCoordinator: Starting all agents...');
    _isRunning = true;
    for (final agent in _agents.values) {
      await agent.init();
    }
    for (final agent in _agents.values) {
      await agent.start();
    }
    debugPrint('MrCoordinator: All agents started');
    _coordinatorLoop();
  }

  Future<void> stopAll() async {
    debugPrint('MrCoordinator: Stopping all agents...');
    _isRunning = false;
    // Create a copy of the values to avoid concurrent modification
    final agentsToStop = _agents.values.toList();
    for (final agent in agentsToStop) {
      await agent.stop();
    }
    debugPrint('MrCoordinator: All agents stopped');
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
        debugPrint('MrCoordinator: Warning - ${agent.name} is not active');
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
        assignedTo: 'MrDeveloper',
        title: 'Fix Rule Violations',
        description: 'Fix ${complianceReport['violations']} rule violations',
        priority: TaskPriority.high,
      ));
    }
    
    if ((qualityReport['issues'] as int) > 0) {
      _pma.addTask(AgentTask(
        id: 'fix_quality_${DateTime.now().millisecondsSinceEpoch}',
        assignedTo: 'MrDeveloper',
        title: 'Fix Quality Issues',
        description: 'Fix ${qualityReport['issues']} quality issues',
        priority: TaskPriority.high,
      ));
    }
  }
  
  void _handleAgentMessage(AgentMessage message) {
    debugPrint('MrCoordinator: Message from ${message.from}: ${message.subject}');
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
    debugPrint('MrCoordinator: Error from ${error.from}: ${error.content}');
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
    debugPrint('MrCoordinator: Status update - ${status.content}');
  }
  
  void _handleRequest(AgentMessage request) {
    debugPrint('MrCoordinator: Request from ${request.from}');
  }
  
  void sendMessageTo(String agentName, AgentMessage message) {
    final agent = _agents[agentName];
    if (agent != null) {
      agent.handleMessage(message);
    }
  }

  void broadcastMessage(AgentMessage message) {
    for (final agent in _agents.values) {
      agent.handleMessage(message);
    }
  }

  Future<void> executeTask(AgentTask task) async {
    debugPrint('MrCoordinator: Executing task: ${task.title}');
    _pma.addTask(task);
  }

  Map<String, dynamic> getComplianceStatus() => _rca.getComplianceReport();
  Map<String, dynamic> getQualityStatus() => _tqa.getQualityReport();

  void dispose() {
    stopAll();
    _messageBus.close();
    for (final agent in _agents.values) {
      agent.dispose();
    }
    _agents.clear();
  }
}

// Global singleton instance
MrCoordinator? _coordinatorInstance;
MrCoordinator get coordinator {
  _coordinatorInstance ??= MrCoordinator();
  return _coordinatorInstance!;
}
bool get isCoordinatorInitialized => _coordinatorInstance != null;
