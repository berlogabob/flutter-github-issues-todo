import 'package:flutter/material.dart';

import '../../../design_tokens/tokens.dart';
import '../../../theme/industrial_theme.dart';
import '../../../theme/widgets/widgets.dart';

/// Reusable settings tile component
///
/// Standard tile for settings screens with:
/// - Icon with technical styling
/// - Title and optional subtitle
/// - Optional monospace subtitle for data display
/// - Destructive action support
/// - Enabled/disabled states
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isDestructive;
  final bool monospaceSubtitle;

  const SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.enabled = true,
    this.isDestructive = false,
    this.monospaceSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final textColor = enabled
        ? industrialTheme.textPrimary
        : industrialTheme.textTertiary;
    final iconColor = isDestructive
        ? industrialTheme.statusError
        : (enabled
            ? industrialTheme.textSecondary
            : industrialTheme.textTertiary);

    return IndustrialCard(
      type: onTap != null && enabled
          ? IndustrialCardType.interactive
          : IndustrialCardType.data,
      onTap: enabled ? onTap : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDestructive
                  ? industrialTheme.statusError.withValues(alpha: 0.1)
                  : industrialTheme.surfacePrimary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: isDestructive
                    ? industrialTheme.statusError
                    : industrialTheme.borderPrimary,
                width: 1,
              ),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.md),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: (monospaceSubtitle
                            ? AppTypography.monoAnnotation
                            : AppTypography.captionSmall)
                        .copyWith(
                          color: isDestructive
                              ? industrialTheme.statusError
                              : industrialTheme.textTertiary,
                        ),
                  ),
                ],
              ],
            ),
          ),

          // Chevron
          if (onTap != null && enabled)
            Icon(
              Icons.chevron_right_outlined,
              color: industrialTheme.textTertiary,
            ),
        ],
      ),
    );
  }
}

/// Section header component for settings screens
///
/// Technical-style header with:
/// - Monospace font
/// - Accent color indicator bar
/// - Optional destructive styling
class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final bool isDestructive;

  const SettingsSectionHeader({
    required this.title,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          color: isDestructive
              ? industrialTheme.statusError
              : industrialTheme.accentPrimary,
        ),
        const SizedBox(width: AppSpacing.sm),
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
      ],
    );
  }
}

/// App version footer component
///
/// Technical annotation style footer displaying:
/// - App version with status dot
/// - Platform info
/// - Author attribution
class SettingsAppVersion extends StatelessWidget {
  final String version;
  final String platform;
  final String author;

  const SettingsAppVersion({
    super.key,
    this.version = '1.0.0+2',
    this.platform = 'Flutter',
    this.author = 'BerlogaBob',
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Center(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: industrialTheme.accentPrimary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'GitDoIt v$version',
                style: AppTypography.monoAnnotation.copyWith(
                  color: industrialTheme.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Built with $platform',
            style: AppTypography.captionSmall.copyWith(
              color: industrialTheme.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          RichText(
            text: TextSpan(
              text: 'by ',
              style: AppTypography.captionSmall.copyWith(
                color: industrialTheme.textTertiary.withValues(alpha: 0.7),
              ),
              children: [
                TextSpan(
                  text: author,
                  style: AppTypography.captionSmall.copyWith(
                    color: industrialTheme.textTertiary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: ' with ❤️ from Portugal',
                  style: AppTypography.captionSmall.copyWith(
                    color: industrialTheme.textTertiary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
