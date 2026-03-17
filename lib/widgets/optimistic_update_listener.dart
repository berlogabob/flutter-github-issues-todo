import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../providers/issue_operations_provider.dart';

/// Widget that shows a snackbar when an optimistic operation fails
/// Provides undo functionality to rollback the operation
class OptimisticUpdateListener extends ConsumerWidget {
  final Widget child;

  const OptimisticUpdateListener({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(issueOperationsProvider);

    // Listen for errors and show snackbar
    state.whenData((data) {
      if (data.error != null && data.error!.isNotEmpty) {
        // Show error snackbar with undo option
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            _showErrorSnackBar(context, ref, data.error!);
          }
        });
      }
    });

    return child;
  }

  void _showErrorSnackBar(BuildContext context, WidgetRef ref, String error) {
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
                    error.length > 100 ? '${error.substring(0, 100)}...' : error,
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
                ref.read(issueOperationsProvider.notifier).rollbackOperation(lastOp.id);
              }
            });
          },
        ),
      ),
    );

    // Clear error after showing
    ref.read(issueOperationsProvider.notifier).clearError();
  }
}

/// Extension to easily wrap a screen with optimistic update listener
extension OptimisticUpdateExtension on Widget {
  Widget withOptimisticUpdates() {
    return OptimisticUpdateListener(child: this);
  }
}
