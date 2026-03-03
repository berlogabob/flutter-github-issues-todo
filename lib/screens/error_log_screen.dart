import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';
import '../services/error_logging_service.dart';
import '../widgets/braille_loader.dart';

/// Screen for viewing and managing error logs.
///
/// Features:
/// - View all logged errors
/// - Expand/collapse error details
/// - Clear all errors
/// - Export error log
/// - Copy error details to clipboard
class ErrorLogScreen extends StatefulWidget {
  /// Creates the error log screen.
  const ErrorLogScreen({super.key});

  @override
  State<ErrorLogScreen> createState() => _ErrorLogScreenState();
}

class _ErrorLogScreenState extends State<ErrorLogScreen> {
  final ErrorLoggingService _errorService = ErrorLoggingService.instance;
  List<LogEntry> _errors = [];
  bool _isLoading = true;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _loadErrors();
  }

  Future<void> _loadErrors() async {
    setState(() => _isLoading = true);
    try {
      await _errorService.init();
      final errors = await _errorService.getErrors();
      if (mounted) {
        setState(() {
          _errors = errors;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading errors: $e');
      debugPrint('Stack: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearErrors() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.red),
            SizedBox(width: 8),
            Text('Clear Error Log', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Are you sure you want to clear all error logs? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _errorService.clearErrors();
      await _loadErrors();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error log cleared'),
            backgroundColor: AppColors.orangePrimary,
          ),
        );
      }
    }
  }

  Future<void> _exportErrors() async {
    try {
      final exportPath = await _errorService.exportErrors();
      if (exportPath != null && mounted) {
        // Share the file
        final result = await Share.shareXFiles(
          [XFile(exportPath)],
          subject: 'GitDoIt Error Log',
          text: 'Error log exported from GitDoIt',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.status == ShareResultStatus.success
                    ? 'Error log shared successfully'
                    : 'Error log export complete',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error exporting: $e');
      debugPrint('Stack: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export error log'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Error Log',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Export button
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.orangePrimary),
            onPressed: _isLoading ? null : _exportErrors,
            tooltip: 'Export Error Log',
          ),
          // Clear button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.red),
            onPressed: _isLoading ? null : _clearErrors,
            tooltip: 'Clear Error Log',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _loadErrors,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BrailleLoader(size: 32),
            SizedBox(height: 16),
            Text(
              'Loading error log...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errors.isEmpty) {
      return _buildEmptyState();
    }

    return _buildErrorList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppColors.success.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Errors Logged',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Great! No errors have been recorded.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorList() {
    return Column(
      children: [
        // Summary bar
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.cardBackground,
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: _getLevelColor(ErrorLevel.error),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '${_errors.length} Error${_errors.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Tap to view details',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Error list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _errors.length,
            itemBuilder: (context, index) {
              return _buildErrorCard(index, _errors[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(int index, LogEntry entry) {
    final isExpanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getLevelColor(entry.level).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Level indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getLevelColor(entry.level),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Timestamp
                  Text(
                    entry.formattedTimestamp,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Level badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getLevelColor(entry.level).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.level.name.toUpperCase(),
                      style: TextStyle(
                        color: _getLevelColor(entry.level),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Expand icon
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Message preview
          if (!isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                entry.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          // Expanded details
          if (isExpanded) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full message
                  Text(
                    entry.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Error details
                  if (entry.error != null && entry.error!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Error:',
                      style: TextStyle(
                        color: _getLevelColor(entry.level),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      entry.error!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  // Stack trace
                  if (entry.stackTrace != null && entry.stackTrace!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Stack Trace:',
                      style: TextStyle(
                        color: _getLevelColor(entry.level),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          entry.stackTrace!,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Action buttons
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onPressed: () {
                            final text = '${entry.message}\n\nError: ${entry.error}\n\nStackTrace: ${entry.stackTrace}';
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error details copied'),
                                backgroundColor: AppColors.orangePrimary,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                      if (entry.stackTrace != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.bug_report, size: 16),
                            label: const Text('Report'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () {
                              // Could integrate with crash reporting
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error report feature coming soon'),
                                  backgroundColor: AppColors.orangePrimary,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getLevelColor(ErrorLevel level) {
    switch (level) {
      case ErrorLevel.debug:
        return Colors.blue;
      case ErrorLevel.info:
        return Colors.green;
      case ErrorLevel.warning:
        return Colors.orange;
      case ErrorLevel.error:
        return AppColors.red;
      case ErrorLevel.critical:
        return Colors.purple;
    }
  }
}
