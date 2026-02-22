import 'package:flutter/material.dart';

import '../design_tokens/tokens.dart';
import '../theme/industrial_theme.dart';

/// Reusable repository header widget with collapsible toggle
///
/// Displays a single repository with:
/// - Repository icon
/// - Repository name (owner/name)
/// - Collapsed/expanded state indicator
/// - Tap to toggle visibility
class RepoHeaderWidget extends StatelessWidget {
  final String repoFullName;
  final bool isCollapsed;
  final bool isDefault;
  final VoidCallback onToggle;

  const RepoHeaderWidget({
    super.key,
    required this.repoFullName,
    required this.isCollapsed,
    required this.onToggle,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: industrialTheme.surfaceElevated,
        border: Border(
          bottom: BorderSide(color: industrialTheme.borderPrimary, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Repository icon
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: industrialTheme.accentSubtle,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Icon(
              Icons.folder_outlined,
              size: 16,
              color: industrialTheme.accentPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Repository name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  repoFullName,
                  style: AppTypography.monoData.copyWith(
                    color: industrialTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isDefault ? 'DEFAULT' : (isCollapsed ? 'HIDDEN' : 'VISIBLE'),
                  style: AppTypography.monoAnnotation.copyWith(
                    color: isDefault
                        ? industrialTheme.accentPrimary
                        : (isCollapsed
                              ? industrialTheme.textTertiary
                              : industrialTheme.statusSuccess),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Expand/collapse arrow
          GestureDetector(
            onTap: onToggle,
            child: AnimatedRotation(
              turns: isCollapsed ? -0.25 : 0,
              duration: AppAnimations.durationFast,
              child: Icon(
                Icons.keyboard_arrow_down_outlined,
                color: industrialTheme.accentPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder widget when no repository is configured
class RepoHeaderPlaceholder extends StatelessWidget {
  final VoidCallback? onToggle;
  final bool isCollapsed;

  const RepoHeaderPlaceholder({
    super.key,
    this.onToggle,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Expand/collapse arrow on RIGHT
          if (onToggle != null)
            GestureDetector(
              onTap: onToggle,
              child: AnimatedRotation(
                turns: isCollapsed ? -0.25 : 0,
                duration: AppAnimations.durationFast,
                child: Icon(
                  Icons.keyboard_arrow_down_outlined,
                  color: industrialTheme.accentPrimary,
                  size: 20,
                ),
              ),
            )
          else
            const SizedBox(width: 20),
          const SizedBox(width: AppSpacing.xs),

          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: industrialTheme.accentSubtle,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Icon(
              Icons.folder_outlined,
              size: 16,
              color: industrialTheme.accentPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'NO REPOSITORY CONFIGURED',
              style: AppTypography.monoAnnotation.copyWith(
                color: industrialTheme.textTertiary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
