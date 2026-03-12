import 'dart:async';
import 'package:flutter/foundation.dart';

/// Base class for all GitDoIt agents
abstract class BaseAgent {
  final String name;
  final String role;
  final List<String> responsibilities;

  /// Protected setter for active state - subclasses can set this
  bool _isActive = false;
  final _messageController = StreamController<AgentMessage>.broadcast();

  BaseAgent({
    required this.name,
    required this.role,
    required this.responsibilities,
  });

  bool get isActive => _isActive;
  /// Protected setter for subclasses to update active state
  set isActive(bool value) => _isActive = value;
  Stream<AgentMessage> get messageStream => _messageController.stream;
  
  Future<void> init();
  Future<void> start();
  
  Future<void> stop() async {
    _isActive = false;
    debugPrint('$name: Agent stopped');
  }
  
  void sendMessage(AgentMessage message) {
    _messageController.add(message);
  }
  
  void handleMessage(AgentMessage message);
  Future<void> execute();
  
  void dispose() {
    _messageController.close();
  }
  
  @override
  String toString() => '$name ($role)';
}

enum AgentMessageType {
  task,
  status,
  error,
  request,
  response,
  broadcast,
}

class AgentMessage {
  final String from;
  final String? to;
  final AgentMessageType type;
  final String subject;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  
  AgentMessage({
    required this.from,
    this.to,
    required this.type,
    required this.subject,
    required this.content,
    this.metadata,
  }) : timestamp = DateTime.now();
  
  @override
  String toString() => '[$type] $from: $subject - $content';
}

enum TaskPriority {
  low,
  normal,
  high,
  critical,
}

class AgentTask {
  final String id;
  final String assignedTo;
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime deadline;
  bool isCompleted;
  String? result;
  
  AgentTask({
    required this.id,
    required this.assignedTo,
    required this.title,
    required this.description,
    this.priority = TaskPriority.normal,
    DateTime? deadline,
    this.isCompleted = false,
    this.result,
  }) : deadline = deadline ?? DateTime.now().add(const Duration(hours: 24));
  
  void complete({String? result}) {
    isCompleted = true;
    this.result = result;
  }
}
