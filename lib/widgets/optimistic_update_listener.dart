import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../providers/issue_operations_provider.dart';

/// Widget that shows a snackbar when an optimistic operation fails
/// Provides undo functionality to rollback the operation
class OptimisticUpdateListener extends ConsumerStatefulWidget {
  final Widget child;

  const OptimisticUpdateListener({super.key, required this.child});

  @override
  ConsumerState<OptimisticUpdateListener> createState() =>
      _OptimisticUpdateListenerState();
}

class _OptimisticUpdateListenerState
    extends ConsumerState<OptimisticUpdateListener> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(issueOperationsProvider, (previous, next) {
      next.whenData((data) {
        final previousError = previous?.value?.error;
        final currentError = data.error;
        if (currentError == null || currentError.isEmpty) {
          return;
        }
        if (currentError == previousError) {
          return;
        }
        if (!mounted) {
          return;
        }
        _showErrorSnackBar(currentError);
      });
    });
  }

  void _showErrorSnackBar(String error) {
    if (!mounted) {
      return;
    }
    final messengerState = ScaffoldMessenger.of(context);

    messengerState.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sync failed',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    error.length > 100
                        ? '${error.substring(0, 100)}...'
                        : error,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            // Rollback the last operation
            final state = ref.read(issueOperationsProvider);
            state.whenData((data) {
              if (data.pendingOperations.isNotEmpty) {
                final lastOp = data.pendingOperations.last;
                ref
                    .read(issueOperationsProvider.notifier)
                    .rollbackOperation(lastOp.id);
              }
            });
          },
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(issueOperationsProvider.notifier).clearError();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extension to easily wrap a screen with optimistic update listener
extension OptimisticUpdateExtension on Widget {
  Widget withOptimisticUpdates() {
    return OptimisticUpdateListener(child: this);
  }
}
