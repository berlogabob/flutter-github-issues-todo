import 'package:flutter/material.dart';

import '../../design_tokens/tokens.dart';
import '../../theme/industrial_theme.dart';
import 'industrial_card.dart';
import 'industrial_button.dart';

/// Empty State Widget - Standard pattern for empty screens
///
/// Usage:
/// ```dart
/// EmptyStateWidget(
///   icon: Icons.inbox_outlined,
///   title: 'NO ISSUES',
///   subtitle: 'Connect a repository to see issues',
///   actionLabel: 'SET REPOSITORY',
///   onAction: () => _openSettings(),
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: industrialTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                border: Border.all(
                  color: industrialTheme.borderPrimary,
                  width: 1,
                ),
              ),
              child: Icon(icon, size: 40, color: industrialTheme.textTertiary),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Title
            Text(
              title,
              style: AppTypography.monoAnnotation.copyWith(
                color: industrialTheme.textTertiary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Subtitle
            Text(
              subtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: industrialTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            // Actions
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              IndustrialButton(
                onPressed: onAction,
                label: actionLabel!,
                variant: IndustrialButtonVariant.primary,
                size: IndustrialButtonSize.medium,
              ),
            ],

            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: AppSpacing.sm),
              IndustrialButton(
                onPressed: onSecondaryAction,
                label: secondaryActionLabel!,
                variant: IndustrialButtonVariant.text,
                size: IndustrialButtonSize.small,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading State Widget - Standard pattern for loading screens
///
/// Usage:
/// ```dart
/// LoadingStateWidget(
///   message: 'Loading issues...',
/// )
/// ```
class LoadingStateWidget extends StatelessWidget {
  final String? message;
  final bool showProgress;

  const LoadingStateWidget({super.key, this.message, this.showProgress = true});

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showProgress)
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                industrialTheme.accentPrimary,
              ),
            ),

          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              message!,
              style: AppTypography.monoAnnotation.copyWith(
                color: industrialTheme.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error State Widget - Standard pattern for error screens
///
/// Usage:
/// ```dart
/// ErrorStateWidget(
///   message: 'Failed to load issues',
///   retryAction: () => _retry(),
/// )
/// ```
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final String? errorDetails;
  final VoidCallback? retryAction;
  final String? retryLabel;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.errorDetails,
    this.retryAction,
    this.retryLabel = 'RETRY',
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: industrialTheme.statusError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                border: Border.all(
                  color: industrialTheme.statusError,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: industrialTheme.statusError,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Error message
            Text(
              message,
              style: AppTypography.labelMedium.copyWith(
                color: industrialTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            // Error details
            if (errorDetails != null && errorDetails!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              IndustrialCard(
                type: IndustrialCardType.data,
                backgroundColor: industrialTheme.surfaceSecondary,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  errorDetails!,
                  style: AppTypography.monoAnnotation.copyWith(
                    color: industrialTheme.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],

            // Retry button
            if (retryAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              IndustrialButton(
                onPressed: retryAction,
                label: retryLabel!,
                variant: IndustrialButtonVariant.primary,
                size: IndustrialButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Offline Indicator Widget - Standard pattern for offline state
///
/// Usage:
/// ```dart
/// OfflineBannerWidget(
///   onRetry: () => _checkConnection(),
/// )
/// ```
class OfflineBannerWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineBannerWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: industrialTheme.statusWarning.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: industrialTheme.statusWarning.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off_outlined,
            size: 16,
            color: industrialTheme.statusWarning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'OFFLINE MODE',
              style: AppTypography.labelSmall.copyWith(
                color: industrialTheme.statusWarning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onRetry != null)
            IndustrialButton(
              onPressed: onRetry,
              label: 'RETRY',
              variant: IndustrialButtonVariant.text,
              size: IndustrialButtonSize.small,
            ),
        ],
      ),
    );
  }
}

/// Section Header Widget - Standard pattern for screen sections
///
/// Usage:
/// ```dart
/// SectionHeaderWidget(
///   title: 'ACCOUNT',
///   subtitle: 'Manage your GitHub account',
///   action: IconButton(...),
/// )
/// ```
class SectionHeaderWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool isDestructive;

  const SectionHeaderWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Accent bar
        Container(
          width: 3,
          height: 16,
          color: isDestructive
              ? industrialTheme.statusError
              : industrialTheme.accentPrimary,
        ),

        const SizedBox(width: AppSpacing.sm),

        // Title and subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.monoAnnotation.copyWith(
                  color: isDestructive
                      ? industrialTheme.statusError
                      : industrialTheme.textTertiary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTypography.captionSmall.copyWith(
                    color: industrialTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Action
        // ignore: use_null_aware_elements
        if (action != null) action!,
      ],
    );
  }
}

/// Divider Widget - Standard pattern for list dividers
///
/// Usage:
/// ```dart
/// StandardDivider(),
/// ```
class StandardDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final Color? color;

  const StandardDivider({super.key, this.height, this.thickness, this.color});

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Divider(
      height: height ?? 1,
      thickness: thickness ?? 1,
      color: color ?? industrialTheme.borderPrimary,
    );
  }
}
