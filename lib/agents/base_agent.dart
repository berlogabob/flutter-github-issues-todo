import 'dart:async';

/// Base class for all GitDoIt agents
/// Each agent runs in parallel and communicates through messages
abstract class BaseAgent {
  final String role;
  final String shortName;
  final String description;
  
  final _messageController = StreamController<AgentMessage>.broadcast();
  final _taskQueue = <AgentTask>[];
  
  Stream<AgentMessage> get messageStream => _messageController.stream;
  List<AgentTask> get taskQueue => List.unmodifiable(_taskQueue);
  
  bool _isRunning = false;
  bool get isRunning => _isRunning;
  
  set isRunning(bool value) {
    _isRunning = value;
  }
  
  BaseAgent({
    required this.role,
    required this.shortName,
    required this.description,
  });
  
  /// Start the agent's work loop
  Future<void> start();
  
  /// Stop the agent
  Future<void> stop();
  
  /// Add a task to the agent's queue
  void addTask(AgentTask task) {
    _taskQueue.add(task);
    _messageController.add(AgentMessage(
      from: shortName,
      type: MessageType.taskAssigned,
      data: {'task': task.toJson()},
    ));
  }
  
  /// Send a message to other agents
  void sendMessage(String message, {MessageType type = MessageType.info, Map<String, dynamic>? data}) {
    _messageController.add(AgentMessage(
      from: shortName,
      type: type,
      content: message,
      data: data,
    ));
  }
  
  /// Process a task - to be implemented by specific agents
  Future<AgentTaskResult> processTask(AgentTask task);
  
  /// Get agent status
  AgentStatus getStatus() {
    return AgentStatus(
      agent: shortName,
      isRunning: _isRunning,
      pendingTasks: _taskQueue.length,
      lastActivity: DateTime.now(),
    );
  }
  
  void dispose() {
    _messageController.close();
    _taskQueue.clear();
  }
}

/// Message sent between agents
class AgentMessage {
  final String from;
  final MessageType type;
  final String? content;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  
  AgentMessage({
    required this.from,
    required this.type,
    this.content,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'type': type.toString().split('.').last,
      'content': content,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  factory AgentMessage.fromJson(Map<String, dynamic> json) {
    return AgentMessage(
      from: json['from'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      content: json['content'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Types of messages
enum MessageType {
  info,
  taskAssigned,
  taskCompleted,
  taskFailed,
  request,
  response,
  error,
  statusUpdate,
}

/// Task assigned to an agent
class AgentTask {
  final String id;
  final String assignedTo;
  final String description;
  final DateTime deadline;
  final TaskPriority priority;
  final Map<String, dynamic>? metadata;
  
  AgentTask({
    required this.id,
    required this.assignedTo,
    required this.description,
    required this.deadline,
    this.priority = TaskPriority.medium,
    this.metadata,
  });
  
  TaskStatus status = TaskStatus.pending;
  DateTime? startedAt;
  DateTime? completedAt;
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignedTo': assignedTo,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'metadata': metadata,
    };
  }
  
  factory AgentTask.fromJson(Map<String, dynamic> json) {
    return AgentTask(
      id: json['id'] as String,
      assignedTo: json['assignedTo'] as String,
      description: json['description'] as String,
      deadline: DateTime.parse(json['deadline'] as String),
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
    )..status = TaskStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] as String? ?? 'pending'),
      );
  }
}

/// Priority levels for tasks
enum TaskPriority {
  low,
  medium,
  high,
  critical,
}

/// Status of a task
enum TaskStatus {
  pending,
  inProgress,
  completed,
  failed,
  blocked,
}

/// Result of task processing
class AgentTaskResult {
  final String taskId;
  final bool success;
  final String? output;
  final Map<String, dynamic>? artifacts;
  final List<String>? issues;
  
  AgentTaskResult({
    required this.taskId,
    required this.success,
    this.output,
    this.artifacts,
    this.issues,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'success': success,
      'output': output,
      'artifacts': artifacts,
      'issues': issues,
    };
  }
}

/// Status of an agent
class AgentStatus {
  final String agent;
  final bool isRunning;
  final int pendingTasks;
  final DateTime lastActivity;
  
  AgentStatus({
    required this.agent,
    required this.isRunning,
    required this.pendingTasks,
    required this.lastActivity,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'agent': agent,
      'isRunning': isRunning,
      'pendingTasks': pendingTasks,
      'lastActivity': lastActivity.toIso8601String(),
    };
  }
}
