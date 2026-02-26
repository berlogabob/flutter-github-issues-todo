import 'package:flutter/material.dart';

import '../../models/project_field.dart';
import '../../design_tokens/tokens.dart';
import '../../theme/industrial_theme.dart';
import '../../theme/widgets/widgets.dart';

/// Field Editor Widget - Edit project item fields
///
/// Supports:
/// - Priority (Single Select)
/// - Estimate (Number)
/// - Text fields
/// - Date fields
/// - Iteration fields
class FieldEditor extends StatefulWidget {
  final FieldValue fieldValue;
  final ProjectField field;
  final ValueChanged<dynamic> onValueChanged;

  const FieldEditor({
    super.key,
    required this.fieldValue,
    required this.field,
    required this.onValueChanged,
  });

  @override
  State<FieldEditor> createState() => _FieldEditorState();
}

class _FieldEditorState extends State<FieldEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.fieldValue.displayValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field label
        Row(
          children: [
            Container(
              width: 3,
              height: 12,
              color: industrialTheme.accentPrimary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              widget.field.name.toUpperCase(),
              style: AppTypography.monoAnnotation.copyWith(
                color: industrialTheme.textTertiary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppSpacing.sm),
        
        // Field editor based on type
        _buildEditor(industrialTheme),
      ],
    );
  }

  Widget _buildEditor(IndustrialThemeData industrialTheme) {
    switch (widget.field.dataType) {
      case ProjectFieldType.singleSelect:
        return _buildSingleSelectEditor(industrialTheme);
      case ProjectFieldType.number:
        return _buildNumberEditor(industrialTheme);
      case ProjectFieldType.text:
        return _buildTextEditor(industrialTheme);
      case ProjectFieldType.date:
        return _buildDateEditor(industrialTheme);
      case ProjectFieldType.iteration:
        return _buildIterationEditor(industrialTheme);
    }
  }

  Widget _buildSingleSelectEditor(IndustrialThemeData industrialTheme) {
    if (widget.field.options == null || widget.field.options!.isEmpty) {
      return Text(
        'No options available',
        style: AppTypography.captionSmall.copyWith(
          color: industrialTheme.textTertiary,
        ),
      );
    }

    // Get current selection
    final currentValue = widget.fieldValue.value as Map<String, dynamic>?;
    final currentOptionId = currentValue?['id'] as String?;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: widget.field.options!.map((option) {
        final isSelected = option.id == currentOptionId;
        
        return GestureDetector(
          onTap: () {
            widget.onValueChanged({
              'id': option.id,
              'name': option.name,
              'color': option.color,
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? (option.color != null
                      ? option.colorValue.withOpacity(0.3)
                      : industrialTheme.accentPrimary.withOpacity(0.3))
                  : industrialTheme.surfacePrimary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: isSelected
                    ? (option.color != null
                        ? option.colorValue
                        : industrialTheme.accentPrimary)
                    : industrialTheme.borderPrimary,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              option.name,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? industrialTheme.textPrimary
                    : industrialTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumberEditor(IndustrialThemeData industrialTheme) {
    return IndustrialInput(
      label: widget.field.name,
      controller: _controller,
      inputType: IndustrialInputType.number,
      onChanged: (value) {
        widget.onValueChanged(double.tryParse(value) ?? 0);
      },
    );
  }

  Widget _buildTextEditor(IndustrialThemeData industrialTheme) {
    return IndustrialInput(
      label: widget.field.name,
      controller: _controller,
      inputType: IndustrialInputType.text,
      onChanged: (value) {
        widget.onValueChanged(value);
      },
    );
  }

  Widget _buildDateEditor(IndustrialThemeData industrialTheme) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: widget.fieldValue.value != null
              ? DateTime.parse(widget.fieldValue.value as String)
              : DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );

        if (date != null && mounted) {
          widget.onValueChanged(date.toIso8601String().split('T').first);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: industrialTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: industrialTheme.borderPrimary,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: industrialTheme.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                widget.fieldValue.displayValue.isEmpty
                    ? 'Select date'
                    : widget.fieldValue.displayValue,
                style: AppTypography.bodyMedium.copyWith(
                  color: widget.fieldValue.displayValue.isEmpty
                      ? industrialTheme.textTertiary
                      : industrialTheme.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: industrialTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIterationEditor(IndustrialThemeData industrialTheme) {
    final currentValue = widget.fieldValue.value as Map<String, dynamic>?;
    final currentTitle = currentValue?['title'] as String?;

    return GestureDetector(
      onTap: () {
        // Show iteration picker (simplified as dropdown for now)
        _showIterationPicker(context, industrialTheme);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: industrialTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: industrialTheme.borderPrimary,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: industrialTheme.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                currentTitle ?? 'Select iteration',
                style: AppTypography.bodyMedium.copyWith(
                  color: currentTitle == null
                      ? industrialTheme.textTertiary
                      : industrialTheme.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: industrialTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showIterationPicker(
    BuildContext context,
    IndustrialThemeData industrialTheme,
  ) {
    // Simplified iteration picker - in real app would fetch from project
    final iterations = [
      {'title': 'Sprint 1', 'startDate': '2026-02-01', 'duration': 14},
      {'title': 'Sprint 2', 'startDate': '2026-02-15', 'duration': 14},
      {'title': 'Sprint 3', 'startDate': '2026-03-01', 'duration': 14},
      {'title': 'Sprint 4', 'startDate': '2026-03-15', 'duration': 14},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: industrialTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SELECT ITERATION',
              style: AppTypography.monoAnnotation.copyWith(
                color: industrialTheme.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...iterations.map((iteration) {
              return ListTile(
                title: Text(
                  iteration['title'] as String,
                  style: AppTypography.bodyMedium.copyWith(
                    color: industrialTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${iteration['startDate']} (${iteration['duration']} days)',
                  style: AppTypography.captionSmall.copyWith(
                    color: industrialTheme.textSecondary,
                  ),
                ),
                onTap: () {
                  widget.onValueChanged(iteration);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

/// Field Display Widget - Display field value compactly
class FieldDisplay extends StatelessWidget {
  final FieldValue fieldValue;
  final VoidCallback? onTap;

  const FieldDisplay({
    super.key,
    required this.fieldValue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    if (fieldValue.displayValue.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: fieldValue.color?.withOpacity(0.2) ??
              industrialTheme.surfacePrimary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          border: Border.all(
            color: fieldValue.color ?? industrialTheme.borderPrimary,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fieldValue.color != null)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: fieldValue.color,
                  shape: BoxShape.circle,
                ),
                margin: const EdgeInsets.only(right: AppSpacing.xs),
              ),
            Text(
              fieldValue.displayValue,
              style: AppTypography.captionSmall.copyWith(
                color: fieldValue.color != null
                    ? industrialTheme.textPrimary
                    : industrialTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
