import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/issues_provider.dart';
import '../utils/logger.dart';
import '../design_tokens/tokens.dart';
import '../theme/industrial_theme.dart';
import '../theme/widgets/widgets.dart';
import '../utils/repo_config_parser.dart';
import 'repo_list_picker_screen.dart';

/// Repository Add Menu - Popup menu for adding repositories
///
/// Shows 2-button dialog:
/// - TOP: "Show My Repos" - Navigate to repo list picker
/// - BOTTOM: "Add by URL" - Add repository by URL
class RepoAddMenu {
  /// Show repository add menu from a button
  static Future<void> show({
    required BuildContext context,
    required RelativeRect position,
  }) async {
    final industrialTheme = context.industrialTheme;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: industrialTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
        ),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'ADD REPOSITORY',
                style: AppTypography.headlineSmall.copyWith(
                  color: industrialTheme.textPrimary,
                ),
              ),
            ),
            // TOP: Show My Repos button
            IndustrialButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RepoListPickerScreen(),
                  ),
                );
              },
              label: 'SHOW MY REPOS',
              variant: IndustrialButtonVariant.primary,
              size: IndustrialButtonSize.large,
              icon: const Icon(Icons.folder_outlined),
            ),
            const SizedBox(height: AppSpacing.sm),
            // BOTTOM: Add by URL button
            IndustrialButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showAddByUrlDialog(context);
              },
              label: 'ADD BY URL',
              variant: IndustrialButtonVariant.secondary,
              size: IndustrialButtonSize.large,
              icon: const Icon(Icons.link_outlined),
            ),
          ],
        ),
      ),
    );
  }

  /// Show dialog to add repository by URL
  static void _showAddByUrlDialog(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: industrialTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: industrialTheme.accentSubtle,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Icon(
                Icons.add_outlined,
                color: industrialTheme.accentPrimary,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'ADD REPOSITORY',
              style: AppTypography.headlineSmall.copyWith(
                color: industrialTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter GitHub repository URL:',
                style: AppTypography.bodyMedium.copyWith(
                  color: industrialTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              IndustrialInput(
                label: 'REPOSITORY URL',
                hintText: 'https://github.com/owner/repo',
                controller: urlController,
                autofocus: true,
                inputType: IndustrialInputType.text,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Or use owner/repo format:',
                style: AppTypography.bodyMedium.copyWith(
                  color: industrialTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              IndustrialInput(
                label: 'OWNER/REPO',
                hintText: 'owner/repo',
                controller: urlController,
                inputType: IndustrialInputType.text,
              ),
            ],
          ),
        ),
        actions: [
          IndustrialButton(
            onPressed: () => Navigator.pop(dialogContext),
            label: 'CANCEL',
            variant: IndustrialButtonVariant.text,
            size: IndustrialButtonSize.small,
          ),
          IndustrialButton(
            onPressed: () {
              final input = urlController.text.trim();
              if (input.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a repository URL'),
                  ),
                );
                return;
              }

              final parsed = parseRepositoryInput(input);
              if (parsed == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Invalid format. Use owner/repo or GitHub URL',
                    ),
                    backgroundColor: industrialTheme.statusError,
                  ),
                );
                return;
              }

              Logger.i(
                'Adding repository: ${parsed.owner}/${parsed.repo}',
                context: 'RepoAddMenu',
              );

              // Add to multi-repo configuration
              issuesProvider.addRepository(parsed.owner, parsed.repo);

              // Set as active repository
              issuesProvider.setRepository(parsed.owner, parsed.repo);

              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: industrialTheme.surfacePrimary,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Added ${parsed.owner}/${parsed.repo}',
                        style: AppTypography.labelSmall.copyWith(
                          color: industrialTheme.surfacePrimary,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: industrialTheme.statusSuccess,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                ),
              );
            },
            label: 'ADD',
            variant: IndustrialButtonVariant.primary,
            size: IndustrialButtonSize.small,
          ),
        ],
      ),
    );
  }
}
