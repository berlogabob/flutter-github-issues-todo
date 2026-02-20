import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/issue.dart';
import '../providers/issues_provider.dart';
import '../utils/logger.dart';

/// Edit Issue Screen - Edit title, body, and status
class EditIssueScreen extends StatefulWidget {
  final Issue issue;

  const EditIssueScreen({super.key, required this.issue});

  @override
  State<EditIssueScreen> createState() => _EditIssueScreenState();
}

class _EditIssueScreenState extends State<EditIssueScreen> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.issue.title);
    _bodyController = TextEditingController(text: widget.issue.body ?? '');

    _titleController.addListener(_onTextChanged);
    _bodyController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _confirmDiscardChanges(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Issue'),
          actions: [
            // Save button
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              onPressed: _isLoading ? null : _saveChanges,
              tooltip: 'Save changes',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title field
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Issue title',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 24),

              // Body field
              TextField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Description (Markdown supported)',
                  hintText: 'Enter issue description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                minLines: 5,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 24),

              // Preview section
              if (_hasChanges) ...[
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPreview(),
              ],

              const SizedBox(height: 32),

              // Status toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.issue.isOpen
                                  ? null
                                  : () => _changeStatus('open'),
                              icon: const Icon(Icons.circle_outlined),
                              label: const Text('Open'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: widget.issue.isOpen
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.issue.isOpen
                                  ? () => _changeStatus('closed')
                                  : null,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Closed'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: !widget.issue.isOpen
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.tertiaryContainer
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.isEmpty ? '(No title)' : title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 12),
              MarkdownBody(
                data: body,
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    setState(() => _isLoading = true);

    Logger.i('Saving issue #${widget.issue.number}', context: 'Edit');

    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    final result = await issuesProvider.updateIssue(
      issueNumber: widget.issue.number,
      title: title,
      body: body.isEmpty ? null : body,
    );

    if (!context.mounted) return;

    setState(() => _isLoading = false);

    if (result != null) {
      Logger.i('Issue updated successfully', context: 'Edit');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issue updated successfully')),
      );
      Navigator.pop(context, true); // Return success
    } else {
      Logger.e('Failed to update issue', context: 'Edit');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update issue')));
    }
  }

  Future<void> _changeStatus(String status) async {
    setState(() => _isLoading = true);

    Logger.i(
      'Changing issue #${widget.issue.number} to $status',
      context: 'Edit',
    );

    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    final result = await issuesProvider.updateIssue(
      issueNumber: widget.issue.number,
      state: status,
    );

    if (!context.mounted) return;

    setState(() => _isLoading = false);

    if (result != null) {
      Logger.i('Issue $status successfully', context: 'Edit');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Issue $status successfully')));
      Navigator.pop(context, true);
    } else {
      Logger.e('Failed to change status', context: 'Edit');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to change status')));
    }
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasChanges) {
      return true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }
}
