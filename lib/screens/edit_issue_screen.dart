import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../constants/app_colors.dart';
import '../models/issue_item.dart';
import '../services/github_api_service.dart';
import '../services/local_storage_service.dart';

/// EditIssueScreen - Edit existing issue
/// Allows editing title, body, and labels
class EditIssueScreen extends StatefulWidget {
  final IssueItem issue;
  final String? owner;
  final String? repo;

  const EditIssueScreen({super.key, required this.issue, this.owner, this.repo});

  @override
  State<EditIssueScreen> createState() => _EditIssueScreenState();
}

class _EditIssueScreenState extends State<EditIssueScreen> {
  final GitHubApiService _githubApi = GitHubApiService();
  final LocalStorageService _localStorage = LocalStorageService();
  
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late List<String> _labels;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.issue.title);
    _bodyController = TextEditingController(text: widget.issue.bodyMarkdown ?? '');
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
        title: const Text(
          'Edit Issue',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.orange),
            onPressed: _isSaving ? null : _saveChanges,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
              ),
            )
          : _isSaving
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
                      ),
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
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.orange, width: 2),
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
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.orange, width: 2),
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
                              p: const TextStyle(color: Colors.white70, fontSize: 14),
                              h1: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              h2: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              h3: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              code: const TextStyle(
                                color: AppColors.orange,
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
      label: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
      backgroundColor: AppColors.orange.withValues(alpha: 0.3),
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
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: AppColors.orange),
            SizedBox(width: 4),
            Text(
              'Add Label',
              style: TextStyle(color: AppColors.orange, fontSize: 12),
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
        title: const Text(
          'Add Label',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: labelController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter label name',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
              backgroundColor: AppColors.orange,
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
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title is required'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // For local-only issues, update locally
      if (widget.issue.isLocalOnly) {
        final updatedIssue = IssueItem(
          id: widget.issue.id,
          title: title,
          number: widget.issue.number,
          bodyMarkdown: body.isNotEmpty ? body : null,
          status: widget.issue.status,
          updatedAt: DateTime.now(),
          assigneeLogin: widget.issue.assigneeLogin,
          labels: _labels,
          projectColumnName: widget.issue.projectColumnName,
          isLocalOnly: true,
        );

        // Update in local storage
        await _localStorage.removeLocalIssue(widget.issue.id);
        await _localStorage.saveLocalIssue(updatedIssue);

        if (mounted) {
          Navigator.pop(context, updatedIssue);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Changes saved locally'),
                ],
              ),
              backgroundColor: AppColors.orange,
            ),
          );
        }
        return;
      }

      // For GitHub issues, update via API
      final effectiveOwner = widget.owner ?? 'berlogabob';
      final effectiveRepo = widget.repo ?? 'gitdoit';

      debugPrint('Updating issue #${widget.issue.number} in $effectiveOwner/$effectiveRepo...');

      final updatedIssue = await _githubApi.updateIssue(
        effectiveOwner,
        effectiveRepo,
        widget.issue.number!,
        title: title,
        body: body.isNotEmpty ? body : null,
        labels: _labels.isNotEmpty ? _labels : null,
      );

      if (mounted) {
        Navigator.pop(context, updatedIssue);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Changes saved to GitHub'),
              ],
            ),
            backgroundColor: AppColors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to save changes: $e');

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to save: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _saveChanges,
            ),
          ),
        );
      }
    }
  }
}
