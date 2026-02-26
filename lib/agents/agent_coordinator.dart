import 'dart:async';
import 'base_agent.dart';

/// Coordinator that manages all agents and enables parallel execution
class AgentCoordinator {
  final List<BaseAgent> _agents = [];
  final _messageBus = StreamController<AgentMessage>.broadcast();
  final _statusController = StreamController<Map<String, AgentStatus>>.broadcast();
  
  bool _isRunning = false;
  Timer? _statusTimer;
  
  Stream<AgentMessage> get messageStream => _messageBus.stream;
  Stream<Map<String, AgentStatus>> get statusStream => _statusController.stream;
  
  /// Register an agent with the coordinator
  void registerAgent(BaseAgent agent) {
    _agents.add(agent);
    // Subscribe to agent's messages and broadcast to all
    agent.messageStream.listen((message) {
      _messageBus.add(message);
    });
  }
  
  /// Get an agent by short name
  BaseAgent? getAgent(String shortName) {
    try {
      return _agents.firstWhere((a) => a.shortName == shortName);
    } catch (_) {
      return null;
    }
  }
  
  /// Assign a task to a specific agent
  void assignTask(AgentTask task) {
    final agent = getAgent(task.assignedTo);
    if (agent != null) {
      agent.addTask(task);
    } else {
      _messageBus.add(AgentMessage(
        from: 'COORDINATOR',
        type: MessageType.error,
        content: 'Agent ${task.assignedTo} not found',
        data: {'taskId': task.id},
      ));
    }
  }
  
  /// Assign tasks to multiple agents in parallel
  void assignTasksParallel(List<AgentTask> tasks) {
    for (final task in tasks) {
      assignTask(task);
    }
  }
  
  /// Broadcast a message to all agents
  void broadcast(String message, {MessageType type = MessageType.info, Map<String, dynamic>? data}) {
    for (final agent in _agents) {
      agent.sendMessage(message, type: type, data: data);
    }
  }
  
  /// Send a message to a specific agent
  void sendTo(String agentShortName, String message, {MessageType type = MessageType.info, Map<String, dynamic>? data}) {
    final agent = getAgent(agentShortName);
    agent?.sendMessage(message, type: type, data: data);
  }
  
  /// Start all agents in parallel
  Future<void> startAll() async {
    if (_isRunning) return;
    
    _isRunning = true;
    
    // Start all agents concurrently
    await Future.wait(_agents.map((agent) => agent.start()));
    
    // Start status monitoring
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) => _broadcastStatus());
    
    _messageBus.add(AgentMessage(
      from: 'COORDINATOR',
      type: MessageType.info,
      content: 'All agents started',
      data: {'agentCount': _agents.length},
    ));
  }
  
  /// Stop all agents
  Future<void> stopAll() async {
    if (!_isRunning) return;
    
    _isRunning = false;
    _statusTimer?.cancel();
    
    // Stop all agents concurrently
    await Future.wait(_agents.map((agent) => agent.stop()));
    
    _messageBus.add(AgentMessage(
      from: 'COORDINATOR',
      type: MessageType.info,
      content: 'All agents stopped',
    ));
  }
  
  /// Get status of all agents
  Map<String, AgentStatus> getAllStatuses() {
    return {
      for (final agent in _agents)
        agent.shortName: agent.getStatus(),
    };
  }
  
  void _broadcastStatus() {
    _statusController.add(getAllStatuses());
  }
  
  /// Get all registered agents info
  List<Map<String, dynamic>> getAgentsInfo() {
    return _agents.map((agent) => {
      'role': agent.role,
      'shortName': agent.shortName,
      'description': agent.description,
      'isRunning': agent.isRunning,
    }).toList();
  }
  
  void dispose() {
    _statusTimer?.cancel();
    _messageBus.close();
    _statusController.close();
    for (final agent in _agents) {
      agent.dispose();
    }
    _agents.clear();
  }
}
