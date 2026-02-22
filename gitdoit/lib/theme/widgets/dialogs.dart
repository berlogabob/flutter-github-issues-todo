import 'package:flutter/material.dart';

import '../../design_tokens/tokens.dart';
import '../../theme/industrial_theme.dart';
import '../../theme/widgets/widgets.dart';

/// Confirmation Dialog - Standard pattern for destructive actions
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => ConfirmationDialog(
///     title: 'CLEAR CACHE',
///     message: 'This will remove all cached data.',
///     confirmLabel: 'CLEAR',
///     cancelLabel: 'CANCEL',
///     isDestructive: true,
///     onConfirm: () => _handleClear(),
///   ),
/// );
/// ```
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final VoidCallback? onConfirm;
  final IconData? icon;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'CANCEL',
    this.isDestructive = false,
    this.onConfirm,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return AlertDialog(
      backgroundColor: industrialTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: isDestructive
                  ? industrialTheme.statusError
                  : industrialTheme.accentPrimary,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTypography.headlineSmall.copyWith(
                color: industrialTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: AppTypography.bodyMedium.copyWith(
          color: industrialTheme.textSecondary,
        ),
      ),
      actions: [
        IndustrialButton(
          onPressed: () => Navigator.pop(context),
          label: cancelLabel,
          variant: IndustrialButtonVariant.text,
          size: IndustrialButtonSize.small,
        ),
        IndustrialButton(
          onPressed: () {
            onConfirm?.call();
            Navigator.pop(context);
          },
          label: confirmLabel,
          variant: isDestructive
              ? IndustrialButtonVariant.destructive
              : IndustrialButtonVariant.primary,
          size: IndustrialButtonSize.small,
        ),
      ],
    );
  }
}

/// Info Dialog - Standard pattern for informational messages
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => InfoDialog(
///     title: 'OFFLINE STORAGE',
///     message: 'Manage how much data is stored locally.',
///     actionLabel: 'DONE',
///     onAction: () => _handleAction(),
///   ),
/// );
/// ```
class InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  const InfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel = 'DONE',
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return AlertDialog(
      backgroundColor: industrialTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: industrialTheme.accentPrimary, size: 24),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTypography.headlineSmall.copyWith(
                color: industrialTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: AppTypography.bodyMedium.copyWith(
          color: industrialTheme.textSecondary,
        ),
      ),
      actions: [
        IndustrialButton(
          onPressed: () {
            onAction?.call();
            Navigator.pop(context);
          },
          label: actionLabel,
          variant: IndustrialButtonVariant.primary,
          size: IndustrialButtonSize.small,
        ),
      ],
    );
  }
}

/// Input Dialog - Standard pattern for user input
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => InputDialog(
///     title: 'SET REPOSITORY',
///     label: 'REPOSITORY NAME',
///     hintText: 'e.g., my-repo',
///     confirmLabel: 'SAVE',
///     onConfirm: (value) => _handleSave(value),
///   ),
/// );
/// ```
class InputDialog extends StatefulWidget {
  final String title;
  final String label;
  final String? hintText;
  final String? initialValue;
  final String confirmLabel;
  final String cancelLabel;
  final ValueChanged<String> onConfirm;
  final String? Function(String?)? validator;

  const InputDialog({
    super.key,
    required this.title,
    required this.label,
    this.hintText,
    this.initialValue,
    required this.confirmLabel,
    this.cancelLabel = 'CANCEL',
    required this.onConfirm,
    this.validator,
  });

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return AlertDialog(
      backgroundColor: industrialTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        side: BorderSide(color: industrialTheme.borderPrimary, width: 1),
      ),
      title: Text(
        widget.title,
        style: AppTypography.headlineSmall.copyWith(
          color: industrialTheme.textPrimary,
        ),
      ),
      content: IndustrialInput(
        label: widget.label,
        hintText: widget.hintText,
        controller: _controller,
        validator: widget.validator,
      ),
      actions: [
        IndustrialButton(
          onPressed: () => Navigator.pop(context),
          label: widget.cancelLabel,
          variant: IndustrialButtonVariant.text,
          size: IndustrialButtonSize.small,
        ),
        IndustrialButton(
          onPressed: () {
            if (widget.validator != null) {
              final error = widget.validator!(_controller.text);
              if (error != null) return;
            }
            widget.onConfirm(_controller.text.trim());
            Navigator.pop(context);
          },
          label: widget.confirmLabel,
          variant: IndustrialButtonVariant.primary,
          size: IndustrialButtonSize.small,
        ),
      ],
    );
  }
}
