import 'package:flutter/material.dart';

import '../../../design_tokens/tokens.dart';
import '../../../theme/industrial_theme.dart';

/// Clear data option tile
///
/// Reusable tile for clear data options with:
/// - Icon with technical styling
/// - Title and description
/// - Destructive action support
class ClearDataOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool isDestructive;
  final IndustrialThemeData industrialTheme;

  const ClearDataOption({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.isDestructive = false,
    required this.industrialTheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDestructive
              ? industrialTheme.statusError.withValues(alpha: 0.1)
              : industrialTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isDestructive
                ? industrialTheme.statusError.withValues(alpha: 0.3)
                : industrialTheme.borderPrimary,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: isDestructive
                    ? industrialTheme.statusError.withValues(alpha: 0.2)
                    : industrialTheme.accentSubtle,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive
                    ? industrialTheme.statusError
                    : industrialTheme.accentPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      color: isDestructive
                          ? industrialTheme.statusError
                          : industrialTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    description,
                    style: AppTypography.captionSmall.copyWith(
                      color: isDestructive
                          ? industrialTheme.statusError.withValues(alpha: 0.8)
                          : industrialTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right,
                color: isDestructive
                    ? industrialTheme.statusError
                    : industrialTheme.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
