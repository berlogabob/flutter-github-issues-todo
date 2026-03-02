import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../constants/app_colors.dart';
import '../utils/app_error_handler.dart';
import '../models/issue_item.dart';
import '../models/pending_operation.dart';
import '../services/github_api_service.dart';
import '../services/local_storage_service.dart';
import '../services/pending_operations_service.dart';
import '../services/network_service.dart';
import '../widgets/braille_loader.dart';

/// Screen for editing existing GitHub issues.
///
/// Allows editing:
/// - Issue title
/// - Issue body with Markdown preview
/// - Labels (add/remove)
/// - Supports both local-only and GitHub-synced issues
///
/// Usage:
/// ```dart
/// final result = await Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => EditIssueScreen(
///       issue: issueItem,
///       owner: 'owner',
///       repo: 'repo',
///     ),
///   ),
/// );
/// ```
class EditIssueScreen extends StatefulWidget {
  /// The issue to edit.
  final IssueItem issue;

  /// Repository owner login.
  final String? owner;

  /// Repository name.
  final String? repo;

  /// Creates the edit issue screen.
  ///
  /// [issue] is the issue to be edited (required).
  /// [owner] and [repo] specify the target repository for GitHub-synced issues.
  const EditIssueScreen({
    super.key,
    required this.issue,
    this.owner,
    this.repo,
  });

  @override
  State<EditIssueScreen> createState() => _EditIssueScreenState();
}

class _EditIssueScreenState extends State<EditIssueScreen> {
  final GitHubApiService _githubApi = GitHubApiService();
  final LocalStorageService _localStorage = LocalStorageService();
  final PendingOperationsService _pendingOps = PendingOperationsService();
  final NetworkService _networkService = NetworkService();

  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late List<String> _labels;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.issue.title);
    _bodyController = TextEditingController(
      text: widget.issue.bodyMarkdown ?? '',
    );
    _labels = List.from(widget.issue.labels);
    _isLoading = false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Edit Issue', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.orangePrimary),
            onPressed: _isSaving ? null : _saveChanges,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: BrailleLoader(size: 32))
          : _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BrailleLoader(size: 32),
                  SizedBox(height: 16),
                  Text(
                    'Saving changes...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  _buildSection(
                    title: 'Title',
                    child: TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Issue title',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.orangePrimary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.cardBackground,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Labels
                  _buildSection(
                    title: 'Labels',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._labels.map((label) => _buildLabelChip(label)),
                            _buildAddLabelChip(),
                          ],
                        ),
                        if (_labels.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'No labels yet. Tap + to add.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Body
                  _buildSection(
                    title: 'Description (Markdown)',
                    child: TextField(
                      controller: _bodyController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Write a description using Markdown...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.orangePrimary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.cardBackground,
                      ),
                      maxLines: 15,
                      minLines: 10,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Preview
                  if (_bodyController.text.isNotEmpty) ...[
                    const Text(
                      'Preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: MarkdownBody(
                        data: _bodyController.text,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          h1: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          h2: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          h3: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          code: const TextStyle(
                            color: AppColors.orangePrimary,
                            backgroundColor: Color(0xFF2D2D2D),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildLabelChip(String label) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      backgroundColor: AppColors.orangePrimary.withValues(alpha: 0.3),
      deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
      onDeleted: () => _removeLabel(label),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildAddLabelChip() {
    return GestureDetector(
      onTap: _showAddLabelDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.orangePrimary.withValues(alpha: 0.5),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: AppColors.orangePrimary),
            SizedBox(width: 4),
            Text(
              'Add Label',
              style: TextStyle(color: AppColors.orangePrimary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _removeLabel(String label) {
    setState(() {
      _labels.remove(label);
    });
  }

  void _showAddLabelDialog() {
    final labelController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Add Label', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: labelController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter label name',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _addLabel(value.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (labelController.text.trim().isNotEmpty) {
                _addLabel(labelController.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orangePrimary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addLabel(String label) {
    if (!_labels.contains(label)) {
      setState(() {
        _labels.add(label);
      });
    }
  }

  Future<void> _saveChanges() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title is required'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final body = _bodyController.text.trim();
    final repoFullName = widget.repo;
    if (repoFullName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No repository selected'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final parts = repoFullName.split('/');
    if (parts.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid repository name'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final owner = parts[0];
    final repo = parts[1];

    setState(() => _isSaving = true);

    // CHECK NETWORK
    final isOnline = await _networkService.checkConnectivity();

    if (!isOnline || widget.issue.isLocalOnly) {
      // OFFLINE or LOCAL: Update locally and queue for sync
      try {
        // Update local issue
        final updatedIssue = IssueItem(
          id: widget.issue.id,
          title: title,
          number: widget.issue.number,
          status: widget.issue.status,
          updatedAt: DateTime.now(),
          bodyMarkdown: body,
          assigneeLogin: widget.issue.assigneeLogin,
          labels: _labels,
          isLocalOnly: widget.issue.isLocalOnly,
        );

        await _localStorage.saveLocalIssue(updatedIssue);

        // Queue sync operation if not local-only
        if (!widget.issue.isLocalOnly && widget.issue.number != null) {
          final operationId =
              'update_${widget.issue.id}_${DateTime.now().millisecondsSinceEpoch}';
          final operation = PendingOperation.updateIssue(
            id: operationId,
            issueNumber: widget.issue.number!,
            owner: owner,
            repo: repo,
            data: {'title': title, 'body': body, 'labels': _labels},
          );

          await _pendingOps.addOperation(operation);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: isOnline
                  ? const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Issue updated'),
                      ],
                    )
                  : const Row(
                      children: [
                        Icon(Icons.cloud_off, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Issue queued for sync'),
                      ],
                    ),
              backgroundColor: AppColors.orangePrimary,
            ),
          );
          Navigator.pop(context, updatedIssue);
        }
      } catch (e, stackTrace) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
        setState(() => _isSaving = false);
      }
    } else {
      // ONLINE: Update on GitHub
      try {
        final updatedIssue = await _githubApi.updateIssue(
          owner,
          repo,
          widget.issue.number!,
          title: title,
          body: body.isNotEmpty ? body : null,
          labels: _labels.isNotEmpty ? _labels : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Issue #${updatedIssue.number} updated successfully',
              ),
              backgroundColor: AppColors.orangePrimary,
            ),
          );
          Navigator.pop(context, updatedIssue);
        }
      } catch (e, stackTrace) {
        AppErrorHandler.handle(e, stackTrace: stackTrace, context: context);
        setState(() => _isSaving = false);
      }
    }
  }
}
