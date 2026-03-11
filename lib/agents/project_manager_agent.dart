import 'dart:async';
import 'package:flutter/foundation.dart';
import 'base_agent.dart';

/// Project Manager Agent (PMA) - Coordinates all agents
class ProjectManagerAgent extends BaseAgent {
  final List<AgentTask> _taskBacklog = [];
  final Map<String, AgentTask> _activeTasks = {};
  
  ProjectManagerAgent() : super(
    name: 'ProjectManagerAgent',
    role: 'Project Manager',
    responsibilities: [
      'Coordinate all agents',
      'Assign tasks',
      'Track sprint progress',
      'Make architectural decisions',
      'Resolve conflicts',
    ],
  );
  
  @override
  Future<void> init() async {
    debugPrint('$name: Initialized');
  }
  
  @override
  Future<void> start() async {
    _isActive = true;
    debugPrint('$name: Started - Coordinating team...');
    await execute();
  }
  
  @override
  Future<void> execute() async {
    await _reviewTaskBacklog();
    await _checkSprintProgress();
    await _assignTasks();
  }
  
  void addTask(AgentTask task) {
    _taskBacklog.add(task);
    debugPrint('$name: Added task "${task.title}" for ${task.assignedTo}');
  }
  
  Future<void> _assignTasks() async {
    final pendingTasks = _taskBacklog.where((t) => !t.isCompleted).toList();
    for (final task in pendingTasks) {
      if (!_activeTasks.containsKey(task.id)) {
        _activeTasks[task.id] = task;
        sendMessage(AgentMessage(
          from: name,
          to: task.assignedTo,
          type: AgentMessageType.task,
          subject: 'New Task: ${task.title}',
          content: task.description,
          metadata: {
            'taskId': task.id,
            'priority': task.priority.name,
            'deadline': task.deadline.toIso8601String(),
          },
        ));
      }
    }
  }
  
  Future<void> _reviewTaskBacklog() async {
    _taskBacklog.sort((a, b) => b.priority.index.compareTo(a.priority.index));
  }
  
  Future<void> _checkSprintProgress() async {
    final completed = _taskBacklog.where((t) => t.isCompleted).length;
    final total = _taskBacklog.length;
    if (total > 0) {
      final progress = (completed / total * 100).toInt();
      debugPrint('$name: Sprint progress: $progress% ($completed/$total)');
      sendMessage(AgentMessage(
        from: name,
        type: AgentMessageType.status,
        subject: 'Sprint Progress Update',
        content: 'Current progress: $progress% ($completed/$total tasks)',
      ));
    }
  }
  
  void completeTask(String taskId, {String? result}) {
    final task = _taskBacklog.firstWhere(
      (t) => t.id == taskId,
      orElse: () => throw Exception('Task $taskId not found'),
    );
    task.complete(result: result);
    _activeTasks.remove(taskId);
    debugPrint('$name: Task "$taskId" completed');
  }
  
  @override
  void handleMessage(AgentMessage message) {
    switch (message.type) {
      case AgentMessageType.response:
        final taskId = message.metadata?['taskId'] as String?;
        if (taskId != null) completeTask(taskId, result: message.content);
        break;
      case AgentMessageType.error:
        debugPrint('$name: Received error from ${message.from}: ${message.content}');
        break;
      default:
        break;
    }
  }
}
