import 'dart:async';
import 'base_agent.dart';

/// UI/UX Designer Agent (UDA)
/// Designs interface and interactions according to the brief's style
class UIDesignerAgent extends BaseAgent {
  final Map<String, ScreenSpecification> _screenSpecs = {};
  final ThemeSpecification _theme = ThemeSpecification();
  
  UIDesignerAgent() : super(
    role: 'UI/UX Designer Agent',
    shortName: 'UDA',
    description: 'Описывает структуру экранов, компоненты, цвета, поведение',
  );
  
  @override
  Future<void> start() async {
    isRunning = true;
    sendMessage('UDA started - Designing UI/UX', type: MessageType.statusUpdate);
    _initializeDesignSystem();
  }
  
  @override
  Future<void> stop() async {
    isRunning = false;
    sendMessage('UDA stopped - Design work paused', type: MessageType.statusUpdate);
  }
  
  @override
  Future<AgentTaskResult> processTask(AgentTask task) async {
    task.status = TaskStatus.inProgress;
    task.startedAt = DateTime.now();
    
    try {
      sendMessage('Processing design task ${task.id}', type: MessageType.info);
      
      final result = await _processDesignTask(task);
      
      task.status = TaskStatus.completed;
      task.completedAt = DateTime.now();
      
      sendMessage('Design task ${task.id} completed', 
        type: MessageType.taskCompleted,
        data: {'taskId': task.id});
      
      return result;
    } catch (e, stackTrace) {
      task.status = TaskStatus.failed;
      sendMessage('Design task ${task.id} failed: $e', 
        type: MessageType.taskFailed);
      
      return AgentTaskResult(
        taskId: task.id,
        success: false,
        issues: [e.toString(), stackTrace.toString()],
      );
    }
  }
  
  void _initializeDesignSystem() {
    sendMessage('Initializing design system', type: MessageType.info);
    
    // Define all 7 MVP screens
    _screenSpecs['OnboardingScreen'] = _createOnboardingSpec();
    _screenSpecs['MainDashboardScreen'] = _createMainDashboardSpec();
    _screenSpecs['IssueDetailScreen'] = _createIssueDetailSpec();
    _screenSpecs['ProjectBoardScreen'] = _createProjectBoardSpec();
    _screenSpecs['RepoProjectLibraryScreen'] = _createRepoProjectLibrarySpec();
    _screenSpecs['SearchScreen'] = _createSearchSpec();
    _screenSpecs['SettingsScreen'] = _createSettingsSpec();
    
    sendMessage('Design system initialized with ${_screenSpecs.length} screens', 
      type: MessageType.info);
  }
  
  Future<AgentTaskResult> _processDesignTask(AgentTask task) async {
    final metadata = task.metadata;

    switch (metadata?['type']) {
      case 'theme':
        return _generateThemeSpec(task);
      case 'screen-specs':
        return _generateAllScreenSpecs(task);
      default:
        return _generateDesignSpec(task);
    }
  }
  
  AgentTaskResult _generateThemeSpec(AgentTask task) {
    return AgentTaskResult(
      taskId: task.id,
      success: true,
      output: 'Theme specification generated',
      artifacts: {
        'theme': _theme.toJson(),
      },
    );
  }

  AgentTaskResult _generateAllScreenSpecs(AgentTask task) {
    return AgentTaskResult(
      taskId: task.id,
      success: true,
      output: 'All screen specifications generated',
      artifacts: {
        'screens': _screenSpecs.entries.map((e) => {'name': e.key, ...e.value.toJson()}).toList(),
      },
    );
  }
  
  AgentTaskResult _generateDesignSpec(AgentTask task) {
    return AgentTaskResult(
      taskId: task.id,
      success: true,
      output: 'Design specification generated',
    );
  }
  
  // Screen Specifications
  
  ScreenSpecification _createOnboardingSpec() {
    return ScreenSpecification(
      name: 'OnboardingScreen',
      description: 'First screen - authentication choice',
      components: [
        ComponentSpec(
          name: 'Logo',
          type: 'Icon',
          properties: {
            'icon': 'Icons.checklist_rounded',
            'size': 80,
            'color': AppColors.orange,
          },
        ),
        ComponentSpec(
          name: 'Title',
          type: 'Text',
          properties: {
            'text': 'GitDoIt',
            'fontSize': 32,
            'fontWeight': 'bold',
            'color': 'white',
          },
        ),
        ComponentSpec(
          name: 'Subtitle',
          type: 'Text',
          properties: {
            'text': 'Minimalist GitHub Issues & Projects TODO Manager',
            'fontSize': 14,
            'opacity': 0.7,
          },
        ),
        ComponentSpec(
          name: 'OAuthButton',
          type: 'ElevatedButton',
          properties: {
            'label': 'Login with GitHub',
            'backgroundColor': AppColors.orange,
            'height': 56,
            'borderRadius': 12,
          },
        ),
        ComponentSpec(
          name: 'PATButton',
          type: 'ElevatedButton',
          properties: {
            'label': 'Use Personal Access Token',
            'backgroundColor': AppColors.orange,
            'height': 56,
          },
        ),
        ComponentSpec(
          name: 'OfflineButton',
          type: 'OutlinedButton',
          properties: {
            'label': 'Continue Offline',
            'borderColor': AppColors.orange,
            'height': 56,
          },
        ),
      ],
      layout: LayoutSpec(
        padding: 24,
        alignment: 'center',
        spacing: 16,
      ),
    );
  }
  
  ScreenSpecification _createMainDashboardSpec() {
    return ScreenSpecification(
      name: 'MainDashboardScreen',
      description: 'Main screen with task hierarchy',
      appBar: AppBarSpec(
        title: 'GitDoIt',
        actions: ['sync_icon', 'search', 'settings'],
      ),
      components: [
        ComponentSpec(
          name: 'FilterChips',
          type: 'Row',
          properties: {
            'chips': ['Open', 'Closed', 'All'],
            'spacing': 8,
          },
        ),
        ComponentSpec(
          name: 'ProjectDropdown',
          type: 'DropdownButton',
          properties: {
            'hint': 'All Projects',
            'backgroundColor': AppColors.cardBackground,
          },
        ),
        ComponentSpec(
          name: 'TaskList',
          type: 'ListView',
          properties: {
            'itemType': 'ExpandableItem',
            'padding': 16,
          },
        ),
        ComponentSpec(
          name: 'EmptyState',
          type: 'Column',
          properties: {
            'message': 'Add repository or project',
            'showButton': true,
          },
          condition: 'isEmpty',
        ),
      ],
      floatingActionButton: FloatingActionButtonSpec(
        label: 'New Issue',
        icon: 'Icons.add',
        backgroundColor: AppColors.orange,
      ),
      layout: LayoutSpec(
        padding: 0,
        alignment: 'start',
        spacing: 0,
      ),
    );
  }
  
  ScreenSpecification _createIssueDetailSpec() {
    return ScreenSpecification(
      name: 'IssueDetailScreen',
      description: 'Detailed view of an issue',
      components: [
        ComponentSpec(
          name: 'Title',
          type: 'Text',
          properties: {
            'format': '#123 Title',
            'fontSize': 20,
            'fontWeight': 'bold',
          },
        ),
        ComponentSpec(
          name: 'Metadata',
          type: 'Row',
          properties: {
            'items': ['status_dot', 'assignee', 'relative_time'],
            'spacing': 16,
          },
        ),
        ComponentSpec(
          name: 'Labels',
          type: 'Wrap',
          properties: {
            'spacing': 8,
            'chipType': 'Chip',
          },
        ),
        ComponentSpec(
          name: 'Body',
          type: 'MarkdownBody',
          properties: {
            'textColor': 'white',
            'fontSize': 14,
          },
        ),
        ComponentSpec(
          name: 'ProjectColumn',
          type: 'Dropdown',
          properties: {
            'label': 'Current Column',
            'condition': 'inProject',
          },
        ),
        ComponentSpec(
          name: 'EditButton',
          type: 'ElevatedButton',
          properties: {
            'label': 'Edit Issue',
            'icon': 'Icons.edit',
            'backgroundColor': AppColors.orange,
          },
        ),
        ComponentSpec(
          name: 'CommentButton',
          type: 'OutlinedButton',
          properties: {
            'label': 'Add Comment',
            'icon': 'Icons.comment',
          },
        ),
        ComponentSpec(
          name: 'CloseButton',
          type: 'TextButton',
          properties: {
            'label': 'Close Issue',
            'color': AppColors.red,
            'condition': 'isOpen',
          },
        ),
      ],
      layout: LayoutSpec(
        padding: 16,
        alignment: 'start',
        spacing: 16,
      ),
    );
  }
  
  ScreenSpecification _createProjectBoardSpec() {
    return ScreenSpecification(
      name: 'ProjectBoardScreen',
      description: 'Kanban-style project board',
      appBar: AppBarSpec(
        title: 'Project Board',
      ),
      components: [
        ComponentSpec(
          name: 'Board',
          type: 'ListView',
          properties: {
            'scrollDirection': 'horizontal',
            'padding': 16,
          },
        ),
        ComponentSpec(
          name: 'Column',
          type: 'Container',
          properties: {
            'width': 300,
            'marginRight': 16,
          },
        ),
        ComponentSpec(
          name: 'ColumnHeader',
          type: 'Text',
          properties: {
            'fontSize': 16,
            'fontWeight': 'bold',
            'marginBottom': 12,
          },
        ),
        ComponentSpec(
          name: 'CardList',
          type: 'ReorderableListView',
          properties: {
            'itemType': 'Card',
          },
        ),
        ComponentSpec(
          name: 'Card',
          type: 'Card',
          properties: {
            'backgroundColor': AppColors.cardBackground,
            'marginBottom': 8,
            'content': ['#num', 'title', 'labels', 'assignee', 'time'],
          },
        ),
      ],
      interactions: [
        InteractionSpec(
          type: 'drag_and_drop',
          source: 'Card',
          target: 'Column',
          action: 'move_item_between_columns',
          feedback: 'GraphQL mutation',
        ),
      ],
      layout: LayoutSpec(
        padding: 0,
        alignment: 'start',
        spacing: 0,
      ),
    );
  }
  
  ScreenSpecification _createRepoProjectLibrarySpec() {
    return ScreenSpecification(
      name: 'RepoProjectLibraryScreen',
      description: 'Manage repositories and projects',
      appBar: AppBarSpec(
        title: 'Repositories & Projects',
      ),
      components: [
        ComponentSpec(
          name: 'AddByUrlButton',
          type: 'ElevatedButton',
          properties: {
            'label': 'Add by URL',
            'icon': 'Icons.link',
          },
        ),
        ComponentSpec(
          name: 'FetchReposButton',
          type: 'ElevatedButton',
          properties: {
            'label': 'Fetch my repositories',
            'icon': 'Icons.folder',
          },
        ),
        ComponentSpec(
          name: 'FetchProjectsButton',
          type: 'ElevatedButton',
          properties: {
            'label': 'Fetch my projects',
            'icon': 'Icons.view_kanban',
          },
        ),
        ComponentSpec(
          name: 'ItemList',
          type: 'ListView',
          properties: {
            'itemType': 'ListTile',
          },
        ),
        ComponentSpec(
          name: 'ItemActions',
          type: 'Row',
          properties: {
            'actions': ['set_default', 'remove'],
          },
        ),
      ],
      layout: LayoutSpec(
        padding: 16,
        alignment: 'start',
        spacing: 16,
      ),
    );
  }
  
  ScreenSpecification _createSearchSpec() {
    return ScreenSpecification(
      name: 'SearchScreen',
      description: 'Global search across issues',
      appBar: AppBarSpec(
        title: 'Search',
      ),
      components: [
        ComponentSpec(
          name: 'SearchField',
          type: 'TextField',
          properties: {
            'hintText': 'Search by title, labels, body',
            'prefixIcon': 'Icons.search',
            'autofocus': true,
          },
        ),
        ComponentSpec(
          name: 'ResultsList',
          type: 'ListView',
          properties: {
            'itemType': 'ExpandableItem',
          },
        ),
        ComponentSpec(
          name: 'NoResults',
          type: 'Text',
          properties: {
            'message': 'No results found',
            'opacity': 0.7,
          },
          condition: 'isEmpty',
        ),
      ],
      layout: LayoutSpec(
        padding: 16,
        alignment: 'start',
        spacing: 16,
      ),
    );
  }
  
  ScreenSpecification _createSettingsSpec() {
    return ScreenSpecification(
      name: 'SettingsScreen',
      description: 'App settings and account management',
      appBar: AppBarSpec(
        title: 'Settings',
      ),
      components: [
        ComponentSpec(
          name: 'AccountSection',
          type: 'ListTile',
          properties: {
            'title': 'Account',
            'subtitle': 'Current user info',
            'leading': 'Icons.person',
          },
        ),
        ComponentSpec(
          name: 'LogoutButton',
          type: 'ListTile',
          properties: {
            'title': 'Logout',
            'leading': 'Icons.logout',
            'textColor': AppColors.red,
          },
        ),
        ComponentSpec(
          name: 'DefaultRepoSetting',
          type: 'ListTile',
          properties: {
            'title': 'Default Repository',
            'subtitle': 'Tap to change',
            'leading': 'Icons.folder',
            'trailing': 'chevron',
          },
        ),
        ComponentSpec(
          name: 'DefaultProjectSetting',
          type: 'ListTile',
          properties: {
            'title': 'Default Project',
            'subtitle': 'Tap to change',
            'leading': 'Icons.view_kanban',
            'trailing': 'chevron',
          },
        ),
        ComponentSpec(
          name: 'SyncSection',
          type: 'ListTile',
          properties: {
            'title': 'Sync Settings',
            'leading': 'Icons.sync',
          },
        ),
        ComponentSpec(
          name: 'AutoSyncToggle',
          type: 'SwitchListTile',
          properties: {
            'title': 'Auto-sync on WiFi',
            'secondary': 'Auto-sync on any network',
          },
        ),
        ComponentSpec(
          name: 'DangerZone',
          type: 'ListTile',
          properties: {
            'title': 'Clear Local Cache',
            'leading': 'Icons.delete_forever',
            'textColor': AppColors.red,
          },
        ),
      ],
      layout: LayoutSpec(
        padding: 0,
        alignment: 'start',
        spacing: 0,
      ),
    );
  }
  
  /// Get screen specification
  ScreenSpecification? getScreenSpec(String screenName) {
    return _screenSpecs[screenName];
  }
  
  /// Get all screen specifications
  Map<String, ScreenSpecification> getAllScreenSpecs() {
    return Map.unmodifiable(_screenSpecs);
  }
  
  /// Get theme specification
  ThemeSpecification get theme => _theme;
}

/// Theme specification
class ThemeSpecification {
  final Map<String, String> colors = {
    'background': '#121212',
    'backgroundGradientStart': '#121212',
    'backgroundGradientEnd': '#1E1E1E',
    'cardBackground': '#1E1E1E',
    'orange': '#FF6200',
    'orangeLight': '#FF8A33',
    'red': '#FF3B30',
    'blue': '#0A84FF',
    'white': '#FFFFFF',
    'whiteOpaque': 'rgba(255, 255, 255, 0.7)',
  };
  
  final Map<String, dynamic> typography = {
    'fontFamily': 'system',
    'titleLarge': {'size': 32, 'weight': 'bold'},
    'titleMedium': {'size': 20, 'weight': 'bold'},
    'titleSmall': {'size': 16, 'weight': 'bold'},
    'bodyLarge': {'size': 14, 'weight': 'regular'},
    'bodyMedium': {'size': 14, 'weight': 'regular', 'opacity': 0.7},
    'labelSmall': {'size': 12, 'weight': 'regular'},
    'caption': {'size': 11, 'weight': 'regular'},
  };
  
  final Map<String, double> spacing = {
    'xs': 4,
    'sm': 8,
    'md': 16,
    'lg': 24,
    'xl': 32,
  };
  
  final Map<String, double> borderRadius = {
    'sm': 4,
    'md': 8,
    'lg': 12,
    'xl': 16,
  };
  
  Map<String, dynamic> toJson() {
    return {
      'colors': colors,
      'typography': typography,
      'spacing': spacing,
      'borderRadius': borderRadius,
    };
  }
}

/// Screen specification
class ScreenSpecification {
  final String name;
  final String description;
  final AppBarSpec? appBar;
  final List<ComponentSpec> components;
  final FloatingActionButtonSpec? floatingActionButton;
  final LayoutSpec layout;
  final List<InteractionSpec> interactions;
  
  ScreenSpecification({
    required this.name,
    required this.description,
    this.appBar,
    required this.components,
    this.floatingActionButton,
    required this.layout,
    this.interactions = const [],
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'appBar': appBar?.toJson(),
      'components': components.map((c) => c.toJson()).toList(),
      'floatingActionButton': floatingActionButton?.toJson(),
      'layout': layout.toJson(),
      'interactions': interactions.map((i) => i.toJson()).toList(),
    };
  }
}

/// App Bar specification
class AppBarSpec {
  final String title;
  final List<String> actions;
  
  AppBarSpec({required this.title, this.actions = const []});
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'actions': actions,
    };
  }
}

/// Component specification
class ComponentSpec {
  final String name;
  final String type;
  final Map<String, dynamic> properties;
  final String? condition;
  
  ComponentSpec({
    required this.name,
    required this.type,
    required this.properties,
    this.condition,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'properties': properties,
      'condition': condition,
    };
  }
}

/// Floating Action Button specification
class FloatingActionButtonSpec {
  final String label;
  final String icon;
  final String backgroundColor;
  
  FloatingActionButtonSpec({
    required this.label,
    required this.icon,
    required this.backgroundColor,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'icon': icon,
      'backgroundColor': backgroundColor,
    };
  }
}

/// Layout specification
class LayoutSpec {
  final double padding;
  final String alignment;
  final double spacing;
  
  LayoutSpec({
    required this.padding,
    required this.alignment,
    required this.spacing,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'padding': padding,
      'alignment': alignment,
      'spacing': spacing,
    };
  }
}

/// Interaction specification
class InteractionSpec {
  final String type;
  final String source;
  final String target;
  final String action;
  final String? feedback;
  
  InteractionSpec({
    required this.type,
    required this.source,
    required this.target,
    required this.action,
    this.feedback,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'source': source,
      'target': target,
      'action': action,
      'feedback': feedback,
    };
  }
}

/// App Colors constants
class AppColors {
  static const String orange = '#FF6200';
  static const String orangeLight = '#FF8A33';
  static const String red = '#FF3B30';
  static const String blue = '#0A84FF';
  static const String cardBackground = '#1E1E1E';
}
