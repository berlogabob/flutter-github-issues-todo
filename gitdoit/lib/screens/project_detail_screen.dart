import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/issues_provider.dart';
import '../../services/github_graphql_service.dart';
import '../../design_tokens/tokens.dart';
import '../../theme/industrial_theme.dart';
import '../../theme/widgets/widgets.dart';
import '../utils/logging.dart';
import '../widgets/project_item_card.dart';

/// Project Detail Screen - Board view with columns
///
/// Displays project items in columns based on Status field
class ProjectDetailScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const ProjectDetailScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final GitHubGraphQLService _graphqlService = GitHubGraphQLService();
  
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _fields = [];
  Map<String, dynamic>? _statusField;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  Future<void> _loadProjectData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final projectId = widget.project['id'] as String;

      // Load items and fields in parallel
      final results = await Future.wait([
        _graphqlService.getProjectItems(projectId: projectId),
        _graphqlService.getProjectFields(projectId: projectId),
      ]);

      setState(() {
        _items = results[0] as List<Map<String, dynamic>>;
        _fields = results[1] as List<Map<String, dynamic>>;
        
        // Find Status field (single select)
        _statusField = _fields.firstWhere(
          (field) => field['dataType'] == 'SINGLE_SELECT' && 
                     (field['name'] == 'Status' || field['name'] == 'State'),
          orElse: () => _fields.isNotEmpty ? _fields.first : {},
        );

        _isLoading = false;
      });

      Logger.i('Loaded project data', context: 'ProjectDetail');
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to load project data',
        error: e,
        stackTrace: stackTrace,
        context: 'ProjectDetail',
      );

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _graphqlService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Scaffold(
      backgroundColor: industrialTheme.surfacePrimary,
      
      // Custom AppBar with project info
      appBar: AppBar(
        backgroundColor: industrialTheme.surfacePrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.project['title'] ?? 'Project',
              style: AppTypography.headlineSmall.copyWith(
                color: industrialTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.project['shortDescription'] != null &&
                widget.project['shortDescription'].isNotEmpty)
              Text(
                widget.project['shortDescription'],
                style: AppTypography.captionSmall.copyWith(
                  color: industrialTheme.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: Icon(
              _isLoading ? Icons.hourglass_empty : Icons.refresh,
              color: industrialTheme.textSecondary,
            ),
            onPressed: _isLoading ? null : _loadProjectData,
          ),
        ],
      ),

      body: _isLoading
          ? _buildLoadingIndicator(industrialTheme)
          : _error != null
              ? _buildErrorState(industrialTheme)
              : _items.isEmpty
                  ? _buildEmptyState(industrialTheme)
                  : _buildBoardView(industrialTheme),

      // FAB to add new item
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(),
        backgroundColor: industrialTheme.accentPrimary,
        child: Icon(
          Icons.add,
          color: industrialTheme.surfacePrimary,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(IndustrialThemeData industrialTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                industrialTheme.accentPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Loading project board...',
            style: AppTypography.bodyMedium.copyWith(
              color: industrialTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(IndustrialThemeData industrialTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: industrialTheme.statusError,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Failed to load project',
            style: AppTypography.headlineSmall.copyWith(
              color: industrialTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _error ?? 'Unknown error',
            style: AppTypography.bodyMedium.copyWith(
              color: industrialTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          IndustrialButton(
            onPressed: _loadProjectData,
            label: 'RETRY',
            variant: IndustrialButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IndustrialThemeData industrialTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: industrialTheme.textTertiary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No items in this project',
            style: AppTypography.headlineSmall.copyWith(
              color: industrialTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Add your first item to get started',
            style: AppTypography.bodyMedium.copyWith(
              color: industrialTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          IndustrialButton(
            onPressed: () => _showAddItemDialog(),
            label: 'ADD ITEM',
            variant: IndustrialButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildBoardView(IndustrialThemeData industrialTheme) {
    // Group items by status column
    final columns = _groupItemsByStatus();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columns.entries.map((entry) {
          return _buildColumn(
            context,
            entry.key,
            entry.value,
            industrialTheme,
          );
        }).toList(),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupItemsByStatus() {
    final columns = <String, List<Map<String, dynamic>>>{};

    // Initialize columns from status field options
    if (_statusField != null && _statusField!['options'] != null) {
      for (final option in _statusField!['options'] as List<dynamic>) {
        columns[option['id'] as String] = [];
      }
    }

    // Group items by their status
    for (final item in _items) {
      String statusId = 'uncategorized';
      
      final fieldValues = item['fieldValues']?['nodes'] as List<dynamic>?;
      if (fieldValues != null && _statusField != null) {
        final statusValue = fieldValues.firstWhere(
          (fv) => fv['field']?['id'] == _statusField!['id'],
          orElse: () => null,
        );
        
        if (statusValue != null && statusValue['name'] != null) {
          // Find option ID by name
          if (_statusField!['options'] != null) {
            final option = (_statusField!['options'] as List<dynamic>).firstWhere(
              (opt) => opt['name'] == statusValue['name'],
              orElse: () => null,
            );
            if (option != null) {
              statusId = option['id'] as String;
            }
          }
        }
      }

      if (!columns.containsKey(statusId)) {
        columns[statusId] = [];
      }
      columns[statusId]!.add(item);
    }

    return columns;
  }

  Widget _buildColumn(
    BuildContext context,
    String columnId,
    List<Map<String, dynamic>> items,
    IndustrialThemeData industrialTheme,
  ) {
    // Get column name from status field options
    String columnName = 'Uncategorized';
    Color columnColor = Colors.grey;
    
    if (_statusField != null && _statusField!['options'] != null) {
      final option = (_statusField!['options'] as List<dynamic>).firstWhere(
        (opt) => opt['id'] == columnId,
        orElse: () => null,
      );
      if (option != null) {
        columnName = option['name'] as String;
        final colorHex = option['color'] as String? ?? 'grey';
        try {
          columnColor = Color(int.parse(colorHex, radix: 16) + 0xFF000000);
        } catch (e) {
          columnColor = Colors.grey;
        }
      }
    }

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: industrialTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: columnColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: columnColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    columnName,
                    style: AppTypography.labelMedium.copyWith(
                      color: industrialTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${items.length}',
                  style: AppTypography.monoAnnotation.copyWith(
                    color: industrialTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Items list
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return DragTarget<Map<String, dynamic>>(
                  onWillAccept: (data) => true,
                  onAccept: (draggedItem) {
                    _moveItemToColumn(draggedItem, columnId);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ProjectItemCard(
                        item: item,
                        onTap: () => _showItemDetail(item),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _moveItemToColumn(
    Map<String, dynamic> item,
    String targetColumnId,
  ) async {
    try {
      final itemId = item['id'] as String;
      final fieldId = _statusField?['id'] as String?;

      if (fieldId == null) {
        Logger.w('Status field not found', context: 'ProjectDetail');
        return;
      }

      await _graphqlService.updateProjectItemField(
        itemId: itemId,
        fieldId: fieldId,
        value: targetColumnId,
      );

      Logger.i('Moved item to column', context: 'ProjectDetail');
      
      // Refresh items
      _loadProjectData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item moved successfully'),
          backgroundColor: context.industrialTheme.statusSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to move item',
        error: e,
        stackTrace: stackTrace,
        context: 'ProjectDetail',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to move item: $e'),
          backgroundColor: context.industrialTheme.statusError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddItemDialog() {
    // Show dialog to add new item to project
    Logger.d('Show add item dialog', context: 'ProjectDetail');
  }

  void _showItemDetail(Map<String, dynamic> content) {
    // Navigate to issue detail screen
    Logger.d('Show item detail', context: 'ProjectDetail');
  }
}
