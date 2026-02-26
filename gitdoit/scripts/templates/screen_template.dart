import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/issues_provider.dart';
import '../utils/logging.dart';
import '../design_tokens/tokens.dart';
import '../theme/industrial_theme.dart';
import '../theme/widgets/widgets.dart';

/// [SCREEN_NAME_PASCAL] - [SCREEN_DESCRIPTION]
///
/// REDESIGNED: Industrial Minimalism with technical layout
/// Monospace labels, modular sections, dot-matrix icons
class [SCREEN_NAME_PASCAL] extends StatelessWidget {
  const [SCREEN_NAME_PASCAL]({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.d('Building [SCREEN_NAME_PASCAL]', context: '[SCREEN_NAME_CAMEL]');

    final industrialTheme = context.industrialTheme;

    return Scaffold(
      backgroundColor: industrialTheme.surfacePrimary,

      // Custom Industrial AppBar
      appBar: AppBar(
        backgroundColor: industrialTheme.surfacePrimary,
        elevation: 0,
        title: Text(
          '[SCREEN_NAME_UPPER]',
          style: AppTypography.monoAnnotation.copyWith(
            color: industrialTheme.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // TODO: Add app bar actions if needed
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // TODO: Add screen content here
          // Use _buildSectionHeader for section divisions
          // Use IndustrialCard, IndustrialButton, IndustrialInput for consistency
          
          _buildSectionHeader(context, 'SECTION TITLE'),
          const SizedBox(height: AppSpacing.md),
          
          // Example card
          IndustrialCard(
            type: IndustrialCardType.data,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Example Content',
                  style: AppTypography.labelMedium.copyWith(
                    color: industrialTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // App version annotation - use pubspec version
          Center(
            child: Row(
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
                  'GitDoIt',
                  style: AppTypography.monoAnnotation.copyWith(
                    color: industrialTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    bool isDestructive = false,
  }) {
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
