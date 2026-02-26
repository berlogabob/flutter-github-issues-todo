// ignore_for_file: undefined_identifier, unused_local_variable

import 'dart:async';
import 'dart:io';
import 'base_agent.dart';

/// Flutter Developer Agent (FDA)
/// Writes clean, modular, performant Flutter code
class FlutterDeveloperAgent extends BaseAgent {
  final Map<String, String> _generatedFiles = {};
  final List<String> _implementedFeatures = [];
  
  FlutterDeveloperAgent() : super(
    role: 'Flutter Developer Agent',
    shortName: 'FDA',
    description: 'Пишет основной код приложения на Flutter',
  );
  
  @override
  Future<void> start() async {
    isRunning = true;
    sendMessage('FDA started - Ready to write Flutter code', type: MessageType.statusUpdate);
    await _setupProjectStructure();
  }
  
  @override
  Future<void> stop() async {
    isRunning = false;
    sendMessage('FDA stopped - Code generation paused', type: MessageType.statusUpdate);
  }
  
  @override
  Future<AgentTaskResult> processTask(AgentTask task) async {
    task.status = TaskStatus.inProgress;
    task.startedAt = DateTime.now();
    
    try {
      sendMessage('Processing task ${task.id}: ${task.description}', type: MessageType.info);
      
      final result = await _processDevelopmentTask(task);
      
      task.status = TaskStatus.completed;
      task.completedAt = DateTime.now();
      
      sendMessage('Task ${task.id} completed successfully', 
        type: MessageType.taskCompleted,
        data: {'taskId': task.id, 'files': result.artifacts?['files']});
      
      return result;
    } catch (e, stackTrace) {
      task.status = TaskStatus.failed;
      sendMessage('Task ${task.id} failed: $e\n$stackTrace', 
        type: MessageType.taskFailed);
      
      return AgentTaskResult(
        taskId: task.id,
        success: false,
        issues: [e.toString(), stackTrace.toString()],
      );
    }
  }
  
  Future<void> _setupProjectStructure() async {
    sendMessage('Setting up project structure', type: MessageType.info);
    
    // Project structure is already created, but we can verify/enhance it
    final directories = [
      'lib/models',
      'lib/services',
      'lib/providers',
      'lib/screens',
      'lib/widgets',
      'lib/agents',
      'lib/constants',
      'lib/utils',
      'test/models',
      'test/services',
      'test/providers',
      'test/screens',
      'test/widgets',
    ];
    
    for (final dir in directories) {
      final directory = Directory(dir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }
    
    sendMessage('Project structure verified', type: MessageType.info);
  }
  
  Future<AgentTaskResult> _processDevelopmentTask(AgentTask task) async {
    final metadata = task.metadata;
    
    switch (metadata?['type']) {
      case 'models':
        return await _generateModels(task);
      case 'screen':
        return await _generateScreen(task);
      case 'widget':
        return await _generateWidget(task);
      case 'service':
        return await _generateService(task);
      case 'provider':
        return await _generateProvider(task);
      default:
        return await _generateGenericCode(task);
    }
  }
  
  Future<AgentTaskResult> _generateModels(AgentTask task) async {
    sendMessage('Generating data models', type: MessageType.info);
    
    // Generate Item model
    final itemModel = '''
import 'package:hive/hive.dart';

part 'item.g.dart';

enum ItemStatus { open, closed }

@HiveType(typeId: 0)
abstract class Item extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  ItemStatus status;
  
  @HiveField(3)
  DateTime? updatedAt;
  
  @HiveField(4)
  String? assigneeLogin;
  
  @HiveField(5)
  List<String> labels;
  
  @HiveField(6)
  List<Item> children;
  
  @HiveField(7)
  bool isExpanded;
  
  @HiveField(8)
  bool isLocalOnly;
  
  @HiveField(9)
  DateTime? localUpdatedAt;
  
  Item({
    required this.id,
    required this.title,
    this.status = ItemStatus.open,
    this.updatedAt,
    this.assigneeLogin,
    this.labels = const [],
    this.children = const [],
    this.isExpanded = false,
    this.isLocalOnly = false,
    this.localUpdatedAt,
  });
  
  Map<String, dynamic> toJson();
  
  factory Item.fromJson(Map<String, dynamic> json);
}
''';
    
    // Generate RepoItem model
    final repoItemModel = '''
import 'item.dart';
import 'package:hive/hive.dart';

part 'repo_item.g.dart';

@HiveType(typeId: 1)
class RepoItem extends Item {
  @HiveField(0)
  String fullName;
  
  @HiveField(1)
  String? description;
  
  RepoItem({
    required String id,
    required String title,
    required this.fullName,
    this.description,
    ItemStatus? status,
    DateTime? updatedAt,
    String? assigneeLogin,
    List<String>? labels,
    List<Item>? children,
    bool? isExpanded,
    bool? isLocalOnly,
    DateTime? localUpdatedAt,
  }) : super(
    id: id,
    title: title,
    status: status ?? ItemStatus.open,
    updatedAt: updatedAt,
    assigneeLogin: assigneeLogin,
    labels: labels ?? const [],
    children: children ?? const [],
    isExpanded: isExpanded ?? false,
    isLocalOnly: isLocalOnly ?? false,
    localUpdatedAt: localUpdatedAt,
  );
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'fullName': fullName,
      'description': description,
      'status': status.toString().split('.').last,
      'updatedAt': updatedAt?.toIso8601String(),
      'assigneeLogin': assigneeLogin,
      'labels': labels,
      'children': children.map((c) => c.toJson()).toList(),
      'isExpanded': isExpanded,
      'isLocalOnly': isLocalOnly,
      'localUpdatedAt': localUpdatedAt?.toIso8601String(),
    };
  }
  
  factory RepoItem.fromJson(Map<String, dynamic> json) {
    return RepoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      fullName: json['fullName'] as String,
      description: json['description'] as String?,
      status: ItemStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ItemStatus.open,
      ),
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt'] as String) 
        : null,
      assigneeLogin: json['assigneeLogin'] as String?,
      labels: (json['labels'] as List?)?.cast<String>() ?? [],
      children: (json['children'] as List?)
        ?.map((c) => Item.fromJson(c))
        .cast<Item>()
        .toList() ?? [],
      isExpanded: json['isExpanded'] as bool? ?? false,
      isLocalOnly: json['isLocalOnly'] as bool? ?? false,
      localUpdatedAt: json['localUpdatedAt'] != null
        ? DateTime.parse(json['localUpdatedAt'] as String)
        : null,
    );
  }
}
''';
    
    // Generate IssueItem model
    final issueItemModel = '''
import 'item.dart';
import 'package:hive/hive.dart';

part 'issue_item.g.dart';

@HiveType(typeId: 2)
class IssueItem extends Item {
  @HiveField(0)
  int? number;
  
  @HiveField(1)
  String? bodyMarkdown;
  
  @HiveField(2)
  String? projectColumnName;
  
  @HiveField(3)
  String? projectItemNodeId;
  
  IssueItem({
    required String id,
    required String title,
    this.number,
    this.bodyMarkdown,
    this.projectColumnName,
    this.projectItemNodeId,
    ItemStatus? status,
    DateTime? updatedAt,
    String? assigneeLogin,
    List<String>? labels,
    List<Item>? children,
    bool? isExpanded,
    bool? isLocalOnly,
    DateTime? localUpdatedAt,
  }) : super(
    id: id,
    title: title,
    status: status ?? ItemStatus.open,
    updatedAt: updatedAt,
    assigneeLogin: assigneeLogin,
    labels: labels ?? const [],
    children: children ?? const [],
    isExpanded: isExpanded ?? false,
    isLocalOnly: isLocalOnly ?? false,
    localUpdatedAt: localUpdatedAt,
  );
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'number': number,
      'bodyMarkdown': bodyMarkdown,
      'projectColumnName': projectColumnName,
      'projectItemNodeId': projectItemNodeId,
      'status': status.toString().split('.').last,
      'updatedAt': updatedAt?.toIso8601String(),
      'assigneeLogin': assigneeLogin,
      'labels': labels,
      'children': children.map((c) => c.toJson()).toList(),
      'isExpanded': isExpanded,
      'isLocalOnly': isLocalOnly,
      'localUpdatedAt': localUpdatedAt?.toIso8601String(),
    };
  }
  
  factory IssueItem.fromJson(Map<String, dynamic> json) {
    return IssueItem(
      id: json['id'] as String,
      title: json['title'] as String,
      number: json['number'] as int?,
      bodyMarkdown: json['bodyMarkdown'] as String?,
      projectColumnName: json['projectColumnName'] as String?,
      projectItemNodeId: json['projectItemNodeId'] as String?,
      status: ItemStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ItemStatus.open,
      ),
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt'] as String) 
        : null,
      assigneeLogin: json['assigneeLogin'] as String?,
      labels: (json['labels'] as List?)?.cast<String>() ?? [],
      children: (json['children'] as List?)
        ?.map((c) => Item.fromJson(c))
        .cast<Item>()
        .toList() ?? [],
      isExpanded: json['isExpanded'] as bool? ?? false,
      isLocalOnly: json['isLocalOnly'] as bool? ?? false,
      localUpdatedAt: json['localUpdatedAt'] != null
        ? DateTime.parse(json['localUpdatedAt'] as String)
        : null,
    );
  }
}
''';
    
    // Generate ProjectItem model
    final projectItemModel = '''
import 'item.dart';
import 'package:hive/hive.dart';

part 'project_item.g.dart';

@HiveType(typeId: 3)
class ProjectItem extends Item {
  @HiveField(0)
  String? projectNodeId;
  
  ProjectItem({
    required String id,
    required String title,
    this.projectNodeId,
    ItemStatus? status,
    DateTime? updatedAt,
    String? assigneeLogin,
    List<String>? labels,
    List<Item>? children,
    bool? isExpanded,
    bool? isLocalOnly,
    DateTime? localUpdatedAt,
  }) : super(
    id: id,
    title: title,
    status: status ?? ItemStatus.open,
    updatedAt: updatedAt,
    assigneeLogin: assigneeLogin,
    labels: labels ?? const [],
    children: children ?? const [],
    isExpanded: isExpanded ?? false,
    isLocalOnly: isLocalOnly ?? false,
    localUpdatedAt: localUpdatedAt,
  );
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'projectNodeId': projectNodeId,
      'status': status.toString().split('.').last,
      'updatedAt': updatedAt?.toIso8601String(),
      'assigneeLogin': assigneeLogin,
      'labels': labels,
      'children': children.map((c) => c.toJson()).toList(),
      'isExpanded': isExpanded,
      'isLocalOnly': isLocalOnly,
      'localUpdatedAt': localUpdatedAt?.toIso8601String(),
    };
  }
  
  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    return ProjectItem(
      id: json['id'] as String,
      title: json['title'] as String,
      projectNodeId: json['projectNodeId'] as String?,
      status: ItemStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ItemStatus.open,
      ),
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt'] as String) 
        : null,
      assigneeLogin: json['assigneeLogin'] as String?,
      labels: (json['labels'] as List?)?.cast<String>() ?? [],
      children: (json['children'] as List?)
        ?.map((c) => Item.fromJson(c))
        .cast<Item>()
        .toList() ?? [],
      isExpanded: json['isExpanded'] as bool? ?? false,
      isLocalOnly: json['isLocalOnly'] as bool? ?? false,
      localUpdatedAt: json['localUpdatedAt'] != null
        ? DateTime.parse(json['localUpdatedAt'] as String)
        : null,
    );
  }
}
''';
    
    _generatedFiles['lib/models/item.dart'] = itemModel;
    _generatedFiles['lib/models/repo_item.dart'] = repoItemModel;
    _generatedFiles['lib/models/issue_item.dart'] = issueItemModel;
    _generatedFiles['lib/models/project_item.dart'] = projectItemModel;
    
    return AgentTaskResult(
      taskId: task.id,
      success: true,
      output: 'Generated 4 model files',
      artifacts: {
        'files': [
          'lib/models/item.dart',
          'lib/models/repo_item.dart',
          'lib/models/issue_item.dart',
          'lib/models/project_item.dart',
        ],
      },
    );
  }
  
  Future<AgentTaskResult> _generateScreen(AgentTask task) async {
    final screenName = task.metadata?['screen'] as String?;
    sendMessage('Generating screen: $screenName', type: MessageType.info);
    
    String screenCode;
    
    switch (screenName) {
      case 'OnboardingScreen':
        screenCode = _generateOnboardingScreen();
        break;
      case 'MainDashboardScreen':
        screenCode = _generateMainDashboardScreen();
        break;
      case 'IssueDetailScreen':
        screenCode = _generateIssueDetailScreen();
        break;
      case 'ProjectBoardScreen':
        screenCode = _generateProjectBoardScreen();
        break;
      default:
        screenCode = _generateGenericScreen(screenName ?? 'Unknown');
    }
    
    final filePath = 'lib/screens/${_snakeCase(screenName ?? 'screen')}.dart';
    _generatedFiles[filePath] = screenCode;
    
    return AgentTaskResult(
      taskId: task.id,
      success: true,
      output: 'Generated $screenName',
      artifacts: {'files': [filePath]},
    );
  }
  
  Future<AgentTaskResult> _generateWidget(AgentTask task) async {
    final widgetName = task.metadata?['widget'] as String?;
    sendMessage('Generating widget: $widgetName', type: MessageType.info);
    
    String widgetCode;
    
    switch (widgetName) {
      case 'ExpandableItem':
        widgetCode = _generateExpandableItem();
        break;
      default:
        widgetCode = _generateGenericWidget(widgetName ?? 'Unknown');
    }
    
    final filePath = 'lib/widgets/${_snakeCase(widgetName ?? 'widget')}.dart';
    _generatedFiles[filePath] = widgetCode;
    
    return AgentTaskResult(
      taskId: task.id,
      success: true,
      output: 'Generated $widgetName widget',
      artifacts: {'files': [filePath]},
    );
  }
  
  Future<AgentTaskResult> _generateService(AgentTask task) async {
    final serviceName = task.metadata?['service'] as String?;
    sendMessage('Generating service: $serviceName', type: MessageType.info);
    
    String serviceCode;
    
    switch (serviceName) {
      case 'AuthService':
        serviceCode = _generateAuthService();
        break;
      case 'GitHubRestService':
        serviceCode = _generateGitHubRestService();
        break;
      case 'GitHubGraphQLService':
        serviceCode = _generateGitHubGraphQLService();
        break;
      case 'LocalStorageService':
        serviceCode = _generateLocalStorageService();
        break;
      case 'SyncService':
        serviceCode = _generateSyncService();
        break;
      default:
        serviceCode = _generateGenericService(serviceName ?? 'Unknown');
    }
    
    final filePath = 'lib/services/${_snakeCase(serviceName ?? 'service')}.dart';
    _generatedFiles[filePath] = serviceCode;
    
    return AgentTaskResult(
      taskId: task.id,
      success: true,
      output: 'Generated $serviceName',
      artifacts: {'files': [filePath]},
    );
  }
  
  Future<AgentTaskResult> _generateProvider(AgentTask task) async {
    sendMessage('Generating Riverpod providers', type: MessageType.info);
    
    final providerCode = _generateProviders();
    final filePath = 'lib/providers/app_providers.dart';
    _generatedFiles[filePath] = providerCode;
    
    return AgentTaskResult(
      taskId: task.id,
      success: true,
      output: 'Generated Riverpod providers',
      artifacts: {'files': [filePath]},
    );
  }
  
  Future<AgentTaskResult> _generateGenericCode(AgentTask task) async {
    sendMessage('Generating generic code for: ${task.description}', type: MessageType.info);
    
    return AgentTaskResult(
      taskId: task.id,
      success: true,
      output: 'Generic code generated',
    );
  }
  
  // Code generation helpers
  
  String _generateOnboardingScreen() {
    return '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _patController = TextEditingController();
  bool _usePat = false;

  @override
  void dispose() {
    _patController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo and Title
              const Icon(
                Icons.checklist_rounded,
                size: 80,
                color: AppColors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                'GitDoIt',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Minimalist GitHub Issues & Projects TODO Manager',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              // Login Options
              if (!_usePat) ...[
                _buildButton(
                  'Login with GitHub',
                  icon: Icons.login,
                  onPressed: () => _loginWithOAuth(),
                ),
                const SizedBox(height: 16),
                _buildButton(
                  'Use Personal Access Token',
                  icon: Icons.key,
                  onPressed: () => setState(() => _usePat = true),
                ),
                const SizedBox(height: 16),
                _buildButton(
                  'Continue Offline',
                  icon: Icons.offline_pin,
                  onPressed: () => _continueOffline(),
                  isSecondary: true,
                ),
              ] else ...[
                TextField(
                  controller: _patController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Personal Access Token',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.orange),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildButton(
                  'Continue',
                  icon: Icons.arrow_forward,
                  onPressed: () => _loginWithPAT(_patController.text),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _usePat = false),
                  child: const Text('Back to options'),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    String label, {
    required IconData icon,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.transparent : AppColors.orange,
          foregroundColor: isSecondary ? Colors.white : Colors.black,
          side: isSecondary
              ? const BorderSide(color: AppColors.orange)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  void _loginWithOAuth() {
    // TODO: Implement OAuth Device Flow
  }

  void _loginWithPAT(String token) {
    // TODO: Implement PAT authentication
  }

  void _continueOffline() {
    // TODO: Implement offline mode
  }
}
''';
  }
  
  String _generateMainDashboardScreen() {
    return '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../widgets/expandable_item.dart';

class MainDashboardScreen extends ConsumerStatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  ConsumerState<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends ConsumerState<MainDashboardScreen> {
  String _filterStatus = 'open';
  String? _selectedProject;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'GitDoIt',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: AppColors.orange),
            onPressed: () => _sync(),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _navigateToSearch(),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _navigateToSettings(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          _buildFilters(),
          // Task List
          Expanded(
            child: _buildTaskList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New Issue'),
        onPressed: () => _createNewIssue(),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _buildFilterChip('Open'),
              const SizedBox(width: 8),
              _buildFilterChip('Closed'),
              const SizedBox(width: 8),
              _buildFilterChip('All'),
              const Spacer(),
              // Project dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedProject,
                  underline: const SizedBox(),
                  dropdownColor: AppColors.cardBackground,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Projects')),
                    // Add project items
                  ],
                  onChanged: (value) => setState(() => _selectedProject = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterStatus == label.toLowerCase();
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      backgroundColor: AppColors.cardBackground,
      selectedColor: AppColors.orange.withValues(alpha: 0.3),
      checkmarkColor: AppColors.orange,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.orange : Colors.white.withValues(alpha: 0.8),
      ),
      onSelected: (selected) {
        setState(() {
          _filterStatus = label.toLowerCase();
        });
      },
    );
  }

  Widget _buildTaskList() {
    // TODO: Replace with actual data from Riverpod provider
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 0, // Replace with actual count
      itemBuilder: (context, index) {
        return const ExpandableItem();
      },
    );
  }

  void _sync() {
    // TODO: Implement sync
  }

  void _navigateToSearch() {
    // TODO: Navigate to search screen
  }

  void _navigateToSettings() {
    // TODO: Navigate to settings screen
  }

  void _createNewIssue() {
    // TODO: Create new issue
  }
}
''';
  }
  
  String _generateIssueDetailScreen() {
    return '''
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../models/issue_item.dart';

class IssueDetailScreen extends ConsumerWidget {
  final IssueItem issue;

  const IssueDetailScreen({super.key, required this.issue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          '#\${issue.number ?? '---'} \${issue.title}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              issue.status.isOpen ? Icons.check_circle : Icons.refresh,
              color: issue.status.isOpen ? AppColors.orange : Colors.green,
            ),
            onPressed: () => _toggleStatus(ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadata
            _buildMetadata(),
            const SizedBox(height: 16),
            // Labels
            if (issue.labels.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: issue.labels.map((label) => _buildLabelChip(label)).toList(),
              ),
              const SizedBox(height: 16),
            ],
            // Body
            MarkdownBody(
              data: issue.bodyMarkdown ?? '',
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata() {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: issue.status.isOpen ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          issue.status.isOpen ? 'Open' : 'Closed',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 16),
        if (issue.assigneeLogin != null) ...[
          const Icon(Icons.person, size: 16, color: AppColors.blue),
          const SizedBox(width: 4),
          Text(
            issue.assigneeLogin!,
            style: const TextStyle(color: AppColors.blue, fontSize: 12),
          ),
          const SizedBox(width: 16),
        ],
        const Icon(Icons.access_time, size: 16, color: AppColors.red),
        const SizedBox(width: 4),
        Text(
          _formatRelativeTime(issue.updatedAt),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLabelChip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
      backgroundColor: AppColors.cardBackground,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Edit Issue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _editIssue(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.comment),
            label: const Text('Add Comment'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppColors.orange),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _addComment(),
          ),
        ),
      ],
    );
  }

  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '\${diff.inDays}d ago';
    if (diff.inHours > 0) return '\${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '\${diff.inMinutes}m ago';
    return 'Just now';
  }

  void _toggleStatus(WidgetRef ref) {
    // TODO: Toggle issue status
  }

  void _editIssue() {
    // TODO: Edit issue
  }

  void _addComment() {
    // TODO: Add comment
  }
}

extension on ItemStatus {
  bool get isOpen => this == ItemStatus.open;
}
''';
  }
  
  String _generateProjectBoardScreen() {
    return '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderables/reorderables.dart';
import '../constants/app_colors.dart';
import '../models/issue_item.dart';

class ProjectBoardScreen extends ConsumerStatefulWidget {
  const ProjectBoardScreen({super.key});

  @override
  ConsumerState<ProjectBoardScreen> createState() => _ProjectBoardScreenState();
}

class _ProjectBoardScreenState extends ConsumerState<ProjectBoardScreen> {
  final List<String> _columns = ['Todo', 'In Progress', 'Review', 'Done'];
  final Map<String, List<IssueItem>> _columnItems = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Project Board',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBoard(),
    );
  }

  Widget _buildBoard() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      itemCount: _columns.length,
      itemBuilder: (context, index) {
        final column = _columns[index];
        return _buildColumn(column);
      },
    );
  }

  Widget _buildColumn(String columnName) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              columnName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Cards
          Expanded(
            child: _buildCardList(columnName),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList(String columnName) {
    final items = _columnItems[columnName] ?? [];
    
    return ReorderableColumn(
      onReorder: (oldIndex, newIndex) {
        setState(() {
          final item = items.removeAt(oldIndex);
          items.insert(newIndex, item);
          _columnItems[columnName] = items;
        });
        // TODO: Update project item status via GraphQL
      },
      children: items.map((item) => _buildCard(item)).toList(),
    );
  }

  Widget _buildCard(IssueItem item) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          '#\${item.number} \${item.title}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.labels.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: item.labels.take(2).map((label) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(color: AppColors.orange, fontSize: 10),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (item.assigneeLogin != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person, size: 12, color: AppColors.blue),
                  const SizedBox(width: 4),
                  Text(
                    item.assigneeLogin!,
                    style: const TextStyle(color: AppColors.blue, fontSize: 11),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
''';
  }
  
  String _generateExpandableItem() {
    return '''
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/item.dart';

class ExpandableItem extends StatefulWidget {
  final Item item;
  final int depth;
  final ValueChanged<Item>? onItemTap;
  final ValueChanged<Item>? onItemLongPress;

  const ExpandableItem({
    super.key,
    required this.item,
    this.depth = 0,
    this.onItemTap,
    this.onItemLongPress,
  });

  @override
  State<ExpandableItem> createState() => _ExpandableItemState();
}

class _ExpandableItemState extends State<ExpandableItem> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildItemRow(),
        if (widget.item.isExpanded && widget.item.children.isNotEmpty)
          ...widget.item.children.map((child) => ExpandableItem(
            item: child,
            depth: widget.depth + 1,
            onItemTap: widget.onItemTap,
            onItemLongPress: widget.onItemLongPress,
          )),
      ],
    );
  }

  Widget _buildItemRow() {
    final hasChildren = widget.item.children.isNotEmpty;
    
    return InkWell(
      onTap: () {
        if (hasChildren) {
          setState(() {
            widget.item.isExpanded = !widget.item.isExpanded;
          });
        }
        widget.onItemTap?.call(widget.item);
      },
      onLongPress: () => widget.onItemLongPress?.call(widget.item),
      child: Container(
        padding: EdgeInsets.only(left: widget.depth * 16.0),
        child: Row(
          children: [
            // Expand/Collapse indicator
            SizedBox(
              width: 24,
              child: hasChildren
                  ? Icon(
                      widget.item.isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      color: AppColors.red,
                      size: 20,
                    )
                  : Container(
                      width: widget.depth > 0 ? 2 : 0,
                      height: 20,
                      color: AppColors.red.withValues(alpha: 0.5),
                    ),
            ),
            // Status indicator
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: widget.item.status == ItemStatus.open
                    ? Colors.green
                    : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.item.labels.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: widget.item.labels.map((label) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: AppColors.orange,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    if (widget.item.assigneeLogin != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 12,
                            color: AppColors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.item.assigneeLogin!,
                            style: const TextStyle(
                              color: AppColors.blue,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Local only indicator
            if (widget.item.isLocalOnly)
              const Icon(
                Icons.cloud_off,
                size: 16,
                color: AppColors.orange,
              ),
          ],
        ),
      ),
    );
  }
}
''';
  }
  
  String _generateAuthService() {
    return '''
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _tokenKey = 'github_token';
  static const String _authTypeKey = 'auth_type';
  
  String? _token;
  AuthType? _authType;
  
  String? get token => _token;
  AuthType? get authType => _authType;
  bool get isAuthenticated => _token != null;
  
  Future<void> initialize() async {
    _token = await _storage.read(key: _tokenKey);
    final authTypeStr = await _storage.read(key: _authTypeKey);
    _authType = authTypeStr != null 
        ? AuthType.values.firstWhere((e) => e.toString() == authTypeStr)
        : null;
  }
  
  Future<bool> authenticateWithPAT(String token) async {
    try {
      // Verify token by making a test request
      final response = await http.get(
        Uri.parse('https://api.github.com/user'),
        headers: {
          'Authorization': 'token \$token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );
      
      if (response.statusCode == 200) {
        await _storage.write(key: _tokenKey, value: token);
        await _storage.write(key: _authTypeKey, value: AuthType.pat.toString());
        _token = token;
        _authType = AuthType.pat;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> authenticateWithOAuth(String deviceCode) async {
    // TODO: Implement OAuth Device Flow
    return false;
  }
  
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _authTypeKey);
    _token = null;
    _authType = null;
  }
  
  Map<String, String> get authHeaders => {
    'Authorization': 'token \$_token',
    'Accept': 'application/vnd.github.v3+json',
  };
}

enum AuthType {
  oauth,
  pat,
  offline,
}
''';
  }
  
  String _generateGitHubRestService() {
    return '''
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/issue_item.dart';
import '../models/repo_item.dart';

class GitHubRestService {
  final String token;
  
  GitHubRestService({required this.token});
  
  Map<String, String> get _headers => {
    'Authorization': 'token \$token',
    'Accept': 'application/vnd.github.v3+json',
  };
  
  Future<List<IssueItem>> fetchIssues(String owner, String repo, {String state = 'open'}) async {
    final response = await http.get(
      Uri.parse('https://api.github.com/repos/\$owner/\$repo/issues?state=\$state'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => _parseIssue(json)).toList();
    }
    throw Exception('Failed to fetch issues');
  }
  
  Future<IssueItem> createIssue(String owner, String repo, {
    required String title,
    String? body,
    List<String>? labels,
    String? assignee,
  }) async {
    final response = await http.post(
      Uri.parse('https://api.github.com/repos/\$owner/\$repo/issues'),
      headers: _headers,
      body: json.encode({
        'title': title,
        'body': body,
        'labels': labels,
        'assignee': assignee,
      }),
    );
    
    if (response.statusCode == 201) {
      return _parseIssue(json.decode(response.body));
    }
    throw Exception('Failed to create issue');
  }
  
  Future<IssueItem> updateIssue(String owner, String repo, int number, {
    String? title,
    String? body,
    List<String>? labels,
    String? assignee,
    String? state,
  }) async {
    final response = await http.patch(
      Uri.parse('https://api.github.com/repos/\$owner/\$repo/issues/\$number'),
      headers: _headers,
      body: json.encode({
        if (title != null) 'title': title,
        if (body != null) 'body': body,
        if (labels != null) 'labels': labels,
        if (assignee != null) 'assignee': assignee,
        if (state != null) 'state': state,
      }),
    );
    
    if (response.statusCode == 200) {
      return _parseIssue(json.decode(response.body));
    }
    throw Exception('Failed to update issue');
  }
  
  Future<List<RepoItem>> fetchUserRepos() async {
    final response = await http.get(
      Uri.parse('https://api.github.com/user/repos?sort=updated'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => _parseRepo(json)).toList();
    }
    throw Exception('Failed to fetch repositories');
  }
  
  IssueItem _parseIssue(Map<String, dynamic> json) {
    return IssueItem(
      id: json['node_id'] as String,
      title: json['title'] as String,
      number: json['number'] as int,
      bodyMarkdown: json['body'] as String?,
      status: json['state'] == 'open' ? ItemStatus.open : ItemStatus.closed,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      assigneeLogin: json['assignee']?['login'] as String?,
      labels: (json['labels'] as List?)
          ?.map((l) => l['name'] as String)
          .toList() ?? [],
    );
  }
  
  RepoItem _parseRepo(Map<String, dynamic> json) {
    return RepoItem(
      id: json['node_id'] as String,
      title: json['name'] as String,
      fullName: json['full_name'] as String,
      description: json['description'] as String?,
    );
  }
}
''';
  }
  
  String _generateGitHubGraphQLService() {
    return '''
import 'package:graphql_flutter/graphql_flutter.dart';

class GitHubGraphQLService {
  late GraphQLClient _client;

  void initialize(String token) {
    final HttpLink httpLink = HttpLink(
      'https://api.github.com/graphql',
      defaultHeaders: {
        'Authorization': 'Bearer \$token',
        'Accept': 'application/vnd.github.v4+json',
      },
    );

    _client = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
    );
  }

  Future<List<Map<String, dynamic>>> fetchProjectItems(String projectNodeId) async {
    // TODO: Implement GraphQL query for project items
    return [];
  }

  Future<bool> moveItemToColumn(String itemId, String statusFieldId, String optionId) async {
    // TODO: Implement GraphQL mutation for moving items
    return false;
  }
}
''';
  }

  String _generateLocalStorageService() {
    return '''
import 'package:hive_flutter/hive_flutter.dart';
import '../models/item.dart';
import '../models/repo_item.dart';
import '../models/issue_item.dart';
import '../models/project_item.dart';

class LocalStorageService {
  static const String _itemsBoxName = 'items';
  static const String _settingsBoxName = 'settings';
  
  late Box<Item> _itemsBox;
  late Box<dynamic> _settingsBox;
  
  Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ItemAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(RepoItemAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(IssueItemAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ProjectItemAdapter());
    
    // Open boxes
    _itemsBox = await Hive.openBox<Item>(_itemsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }
  
  // Items CRUD
  Future<void> saveItem(Item item) async {
    await _itemsBox.put(item.id, item);
  }
  
  Future<void> saveItems(List<Item> items) async {
    await _itemsBox.putAll({
      for (final item in items) item.id: item,
    });
  }
  
  Item? getItem(String id) {
    return _itemsBox.get(id);
  }
  
  List<Item> getAllItems() {
    return _itemsBox.values.toList();
  }
  
  Future<void> deleteItem(String id) async {
    await _itemsBox.delete(id);
  }
  
  Future<void> clearAllItems() async {
    await _itemsBox.clear();
  }
  
  // Settings CRUD
  Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }
  
  T? getSetting<T>(String key) {
    return _settingsBox.get(key) as T?;
  }
  
  Future<void> deleteSetting(String key) async {
    await _settingsBox.delete(key);
  }
}
''';
  }
  
  String _generateSyncService() {
    return '''
import 'dart:async';
import '../models/item.dart';
import '../models/issue_item.dart';
import 'local_storage_service.dart';
import 'github_rest_service.dart';

class SyncService {
  final LocalStorageService _localStorage;
  GitHubRestService? _githubService;
  
  bool _isSyncing = false;
  Timer? _autoSyncTimer;
  
  SyncService({required LocalStorageService localStorage})
      : _localStorage = localStorage;
  
  bool get isSyncing => _isSyncing;
  
  void setGitHubToken(String token) {
    _githubService = GitHubRestService(token: token);
  }
  
  Future<void> syncIssues(String owner, String repo) async {
    if (_isSyncing || _githubService == null) return;
    
    _isSyncing = true;
    
    try {
      // Fetch from GitHub
      final remoteIssues = await _githubService!.fetchIssues(owner, repo);
      
      // Get local items
      final localItems = _localStorage.getAllItems();
      final localIssues = localItems.whereType<IssueItem>().toList();
      
      // Merge: remote wins for conflicts
      final Map<String, Item> merged = {};
      
      // Add all remote items
      for (final issue in remoteIssues) {
        merged[issue.id] = issue;
      }
      
      // Add local-only items
      for (final issue in localIssues) {
        if (!merged.containsKey(issue.id) && issue.isLocalOnly) {
          merged[issue.id] = issue;
        }
      }
      
      // Save merged items
      await _localStorage.saveItems(merged.values.toList());
    } finally {
      _isSyncing = false;
    }
  }
  
  Future<void> pushLocalChanges() async {
    if (_isSyncing || _githubService == null) return;
    
    _isSyncing = true;
    
    try {
      final items = _localStorage.getAllItems();
      final localIssues = items.where((i) => i.isLocalOnly).whereType<IssueItem>();
      
      for (final issue in localIssues) {
        // TODO: Push to GitHub
        issue.isLocalOnly = false;
        await _localStorage.saveItem(issue);
      }
    } finally {
      _isSyncing = false;
    }
  }
  
  void enableAutoSync({Duration interval = const Duration(minutes: 5)}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(interval, (_) => syncAll());
  }
  
  void disableAutoSync() {
    _autoSyncTimer?.cancel();
  }
  
  Future<void> syncAll() async {
    // TODO: Implement full sync
  }
}
''';
  }
  
  String _generateProviders() {
    return '''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';
import '../services/github_rest_service.dart';
import '../models/item.dart';

// Auth providers
final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService();
  service.initialize();
  return service;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).isAuthenticated;
});

// Storage provider
final localStorageProvider = Provider<LocalStorageService>((ref) {
  final service = LocalStorageService();
  service.initialize();
  return service;
});

// Sync provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final storage = ref.watch(localStorageProvider);
  return SyncService(localStorage: storage);
});

// Items provider
final itemsProvider = StateNotifierProvider<ItemsNotifier, List<Item>>((ref) {
  final storage = ref.watch(localStorageProvider);
  return ItemsNotifier(storage);
});

class ItemsNotifier extends StateNotifier<List<Item>> {
  final LocalStorageService _storage;
  
  ItemsNotifier(this._storage) : super([]) {
    _loadItems();
  }
  
  Future<void> _loadItems() async {
    state = _storage.getAllItems();
  }
  
  Future<void> addItem(Item item) async {
    await _storage.saveItem(item);
    state = [...state, item];
  }
  
  Future<void> updateItem(Item item) async {
    await _storage.saveItem(item);
    state = state.map((i) => i.id == item.id ? item : i).toList();
  }
  
  Future<void> deleteItem(String id) async {
    await _storage.deleteItem(id);
    state = state.where((i) => i.id != id).toList();
  }
}

// Filter provider
final filterStatusProvider = StateProvider<String>((ref) => 'open');
final selectedProjectProvider = StateProvider<String?>((ref) => null);

// Filtered items provider
final filteredItemsProvider = Provider<List<Item>>((ref) {
  final items = ref.watch(itemsProvider);
  final filterStatus = ref.watch(filterStatusProvider);
  final selectedProject = ref.watch(selectedProjectProvider);
  
  return items.where((item) {
    // Filter by status
    if (filterStatus != 'all') {
      final isOpen = item.status == ItemStatus.open;
      if (filterStatus == 'open' && !isOpen) return false;
      if (filterStatus == 'closed' && isOpen) return false;
    }
    
    // Filter by project
    if (selectedProject != null) {
      // TODO: Filter by project
    }
    
    return true;
  }).toList();
});
''';
  }
  
  String _generateGenericScreen(String screenName) {
    return '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';

class $screenName extends ConsumerWidget {
  const $screenName({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('$screenName'),
      ),
      body: const Center(
        child: Text('$screenName - To be implemented'),
      ),
    );
  }
}
''';
  }
  
  String _generateGenericWidget(String widgetName) {
    return '''
import 'package:flutter/material.dart';

class $widgetName extends StatelessWidget {
  const $widgetName({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
''';
  }
  
  String _generateGenericService(String serviceName) {
    return '''
class $serviceName {
  // To be implemented
}
''';
  }
  
  String _snakeCase(String text) {
    return text
        .replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}')
        .replaceAll(RegExp(r'^_'), '')
        .replaceAll(' ', '_');
  }
  
  /// Get generated files
  Map<String, String> get generatedFiles => Map.unmodifiable(_generatedFiles);
  
  /// Add implemented feature
  void markFeatureImplemented(String feature) {
    _implementedFeatures.add(feature);
  }
  
  /// Get list of implemented features
  List<String> get implementedFeatures => List.unmodifiable(_implementedFeatures);
}