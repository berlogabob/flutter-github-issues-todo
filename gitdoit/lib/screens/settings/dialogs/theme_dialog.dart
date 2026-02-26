import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_tokens/tokens.dart';
import '../../../theme/industrial_theme.dart';
import '../../../theme/widgets/widgets.dart';
import '../../../services/theme_prefs.dart';
import '../../../providers/theme_provider.dart';

/// Theme selection dialog
///
/// Allows users to choose between:
/// - System Default: Follow device theme settings
/// - Light: Always use light theme
/// - Dark: Always use dark theme
class ThemeDialog extends StatelessWidget {
  const ThemeDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const ThemeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final themeProvider = context.watch<ThemeProvider>();

    return AlertDialog(
      backgroundColor: industrialTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
      ),
      title: Text(
        'THEME',
        style: AppTypography.headlineSmall.copyWith(
          color: industrialTheme.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeOption(
            title: 'System Default',
            subtitle: 'Follow device settings',
            selected: themeProvider.isSystemMode,
            onTap: () {
              themeProvider.setThemeMode(AppThemeMode.system);
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _ThemeOption(
            title: 'Light',
            subtitle: 'Always use light theme',
            selected: themeProvider.isLightMode,
            onTap: () {
              themeProvider.setThemeMode(AppThemeMode.light);
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _ThemeOption(
            title: 'Dark',
            subtitle: 'Always use dark theme',
            selected: themeProvider.isDarkMode,
            onTap: () {
              themeProvider.setThemeMode(AppThemeMode.dark);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

/// Theme option tile widget
class _ThemeOption extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? industrialTheme.accentSubtle
              : industrialTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: selected
                ? industrialTheme.accentPrimary
                : industrialTheme.borderPrimary,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                color: selected
                      ? industrialTheme.accentPrimary
                      : industrialTheme.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: selected
                        ? industrialTheme.accentPrimary
                        : industrialTheme.textPrimary,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  subtitle!,
                  style: AppTypography.captionSmall.copyWith(
                    color: industrialTheme.textTertiary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
