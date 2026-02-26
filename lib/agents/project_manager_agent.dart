import 'dart:async';
import 'base_agent.dart';

/// Project Manager Agent (PMA)
/// Coordinates the team, breaks down work into tasks, monitors deadlines
class ProjectManagerAgent extends BaseAgent {
  final List<AgentTask> _backlog = [];
  final List<AgentTask> _completedTasks = [];
  final _sprintDuration = const Duration(days: 14);
  DateTime? _sprintStart;
  
  ProjectManagerAgent() : super(
    role: 'Project Manager Agent',
    shortName: 'PMA',
    description: 'Координирует команду, разбивает работу на задачи, следит за сроками',
  );
  
  @override
  Future<void> start() async {
    isRunning = true;
    sendMessage('PMA started - Beginning project coordination', type: MessageType.statusUpdate);
    _initializeBacklog();
  }
  
  @override
  Future<void> stop() async {
    isRunning = false;
    sendMessage('PMA stopped - Project coordination paused', type: MessageType.statusUpdate);
  }
  
  @override
  Future<AgentTaskResult> processTask(AgentTask task) async {
    task.status = TaskStatus.inProgress;
    task.startedAt = DateTime.now();
    
    try {
      final result = await _processManagementTask(task);
      task.status = TaskStatus.completed;
      task.completedAt = DateTime.now();
      _completedTasks.add(task);
      
      sendMessage('Task ${task.id} completed', 
        type: MessageType.taskCompleted, 
        data: {'taskId': task.id, 'result': result.toJson()});
      
      return result;
    } catch (e) {
      task.status = TaskStatus.failed;
      sendMessage('Task ${task.id} failed: $e', 
        type: MessageType.taskFailed,
        data: {'taskId': task.id, 'error': e.toString()});
      
      return AgentTaskResult(
        taskId: task.id,
        success: false,
        issues: [e.toString()],
      );
    }
  }
  
  void _initializeBacklog() {
    // Initialize MVP backlog based on the brief
    _backlog.addAll([
      // Authentication
      AgentTask(
        id: 'auth-001',
        assignedTo: 'FDA',
        description: 'Implement OnboardingScreen with OAuth/PAT choice',
        deadline: DateTime.now().add(const Duration(days: 7)),
        priority: TaskPriority.high,
        metadata: {'screen': 'OnboardingScreen', 'type': 'authentication'},
      ),
      AgentTask(
        id: 'auth-002',
        assignedTo: 'FDA',
        description: 'Implement OAuth Device Flow authentication service',
        deadline: DateTime.now().add(const Duration(days: 7)),
        priority: TaskPriority.high,
        metadata: {'service': 'AuthService', 'type': 'authentication'},
      ),
      AgentTask(
        id: 'auth-003',
        assignedTo: 'FDA',
        description: 'Implement PAT (Personal Access Token) authentication',
        deadline: DateTime.now().add(const Duration(days: 7)),
        priority: TaskPriority.high,
        metadata: {'service': 'AuthService', 'type': 'authentication'},
      ),
      
      // Data Models
      AgentTask(
        id: 'model-001',
        assignedTo: 'FDA',
        description: 'Create Item, RepoItem, IssueItem, ProjectItem models',
        deadline: DateTime.now().add(const Duration(days: 3)),
        priority: TaskPriority.critical,
        metadata: {'type': 'models'},
      ),
      
      // Main Dashboard
      AgentTask(
        id: 'screen-001',
        assignedTo: 'FDA',
        description: 'Implement MainDashboardScreen with ExpandableItem hierarchy',
        deadline: DateTime.now().add(const Duration(days: 10)),
        priority: TaskPriority.high,
        metadata: {'screen': 'MainDashboardScreen'},
      ),
      AgentTask(
        id: 'widget-001',
        assignedTo: 'FDA',
        description: 'Create recursive ExpandableItem widget',
        deadline: DateTime.now().add(const Duration(days: 5)),
        priority: TaskPriority.critical,
        metadata: {'widget': 'ExpandableItem'},
      ),
      
      // Issue Detail
      AgentTask(
        id: 'screen-002',
        assignedTo: 'FDA',
        description: 'Implement IssueDetailScreen with markdown support',
        deadline: DateTime.now().add(const Duration(days: 10)),
        priority: TaskPriority.high,
        metadata: {'screen': 'IssueDetailScreen'},
      ),
      
      // Project Board
      AgentTask(
        id: 'screen-003',
        assignedTo: 'FDA',
        description: 'Implement ProjectBoardScreen with drag-and-drop',
        deadline: DateTime.now().add(const Duration(days: 12)),
        priority: TaskPriority.high,
        metadata: {'screen': 'ProjectBoardScreen'},
      ),
      
      // Services
      AgentTask(
        id: 'service-001',
        assignedTo: 'FDA',
        description: 'Implement GitHub REST API service for Issues',
        deadline: DateTime.now().add(const Duration(days: 7)),
        priority: TaskPriority.high,
        metadata: {'service': 'GitHubRestService'},
      ),
      AgentTask(
        id: 'service-002',
        assignedTo: 'FDA',
        description: 'Implement GitHub GraphQL API service for Projects v2',
        deadline: DateTime.now().add(const Duration(days: 7)),
        priority: TaskPriority.high,
        metadata: {'service': 'GitHubGraphQLService'},
      ),
      AgentTask(
        id: 'service-003',
        assignedTo: 'FDA',
        description: 'Implement Hive local storage service',
        deadline: DateTime.now().add(const Duration(days: 5)),
        priority: TaskPriority.critical,
        metadata: {'service': 'LocalStorageService'},
      ),
      AgentTask(
        id: 'service-004',
        assignedTo: 'FDA',
        description: 'Implement sync service for offline-first',
        deadline: DateTime.now().add(const Duration(days: 10)),
        priority: TaskPriority.high,
        metadata: {'service': 'SyncService'},
      ),
      
      // Design tasks
      AgentTask(
        id: 'design-001',
        assignedTo: 'UDA',
        description: 'Define dark theme color scheme and typography',
        deadline: DateTime.now().add(const Duration(days: 2)),
        priority: TaskPriority.critical,
        metadata: {'type': 'theme'},
      ),
      AgentTask(
        id: 'design-002',
        assignedTo: 'UDA',
        description: 'Specify all 7 MVP screens layout and components',
        deadline: DateTime.now().add(const Duration(days: 5)),
        priority: TaskPriority.high,
        metadata: {'type': 'screen-specs'},
      ),
      
      // Testing tasks
      AgentTask(
        id: 'test-001',
        assignedTo: 'TQA',
        description: 'Create unit tests for models',
        deadline: DateTime.now().add(const Duration(days: 5)),
        priority: TaskPriority.medium,
        metadata: {'type': 'unit-tests'},
      ),
      AgentTask(
        id: 'test-002',
        assignedTo: 'TQA',
        description: 'Create widget tests for ExpandableItem',
        deadline: DateTime.now().add(const Duration(days: 7)),
        priority: TaskPriority.medium,
        metadata: {'type': 'widget-tests'},
      ),
      
      // Documentation tasks
      AgentTask(
        id: 'doc-001',
        assignedTo: 'DDA',
        description: 'Create README.md with installation instructions',
        deadline: DateTime.now().add(const Duration(days: 3)),
        priority: TaskPriority.medium,
        metadata: {'file': 'README.md'},
      ),
    ]);
    
    sendMessage('Initialized backlog with ${_backlog.length} tasks', 
      type: MessageType.info,
      data: {'taskCount': _backlog.length});
    
    // Assign initial tasks to agents
    _assignInitialTasks();
  }
  
  void _assignInitialTasks() {
    // Assign critical and high priority tasks first
    final criticalTasks = _backlog.where((t) => 
      t.priority == TaskPriority.critical || t.priority == TaskPriority.high
    ).toList();
    
    for (final task in criticalTasks) {
      sendMessage('Assigning task ${task.id} to ${task.assignedTo}',
        type: MessageType.taskAssigned);
    }
  }
  
  Future<AgentTaskResult> _processManagementTask(AgentTask task) async {
    // PMA processes management tasks
    switch (task.metadata?['type']) {
      case 'sprint-planning':
        return _planSprint(task);
      case 'task-breakdown':
        return _breakDownTask(task);
      default:
        // For standard task assignment, just return success
        return AgentTaskResult(
          taskId: task.id,
          success: true,
          output: 'Task assigned and tracked',
        );
    }
  }
  
  AgentTaskResult _planSprint(AgentTask task) {
    _sprintStart = DateTime.now();
    final sprintEnd = _sprintStart!.add(_sprintDuration);
    
    return AgentTaskResult(
      taskId: task.id,
      success: true,
      output: 'Sprint planned from ${_sprintStart} to $sprintEnd',
      artifacts: {
        'sprintStart': _sprintStart!.toIso8601String(),
        'sprintEnd': sprintEnd.toIso8601String(),
        'tasks': _backlog.map((t) => t.id).toList(),
      },
    );
  }
  
  AgentTaskResult _breakDownTask(AgentTask task) {
    // Break down epic into smaller tasks
    return AgentTaskResult(
      taskId: task.id,
      success: true,
      output: 'Task broken down into subtasks',
    );
  }
  
  /// Get sprint progress
  Map<String, dynamic> getSprintProgress() {
    final total = _backlog.length;
    final completed = _completedTasks.length;
    final inProgress = _backlog.where((t) => t.status == TaskStatus.inProgress).length;
    
    return {
      'sprintStart': _sprintStart?.toIso8601String(),
      'totalTasks': total,
      'completed': completed,
      'inProgress': inProgress,
      'pending': total - completed - inProgress,
      'progress': total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0',
    };
  }
}
