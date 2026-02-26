import 'package:flutter/material.dart';

import '../../models/issue.dart';
import '../../design_tokens/tokens.dart';
import '../../theme/industrial_theme.dart';

/// Label Chip - Displays a GitHub label with color
///
/// Reusable widget for showing labels in issues
class LabelChip extends StatelessWidget {
  final Label label;
  final VoidCallback? onTap;
  final bool showBorder;

  const LabelChip({
    super.key,
    required this.label,
    this.onTap,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;
    
    // Parse color from hex string (e.g., 'CCCCCC' or '#CCCCCC')
    Color labelColor;
    try {
      final colorHex = label.color.replaceAll('#', '');
      labelColor = Color(int.parse(colorHex, radix: 16) + 0xFF000000);
    } catch (e) {
      labelColor = Colors.grey;
    }

    final textColor = _getContrastingTextColor(labelColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: labelColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: showBorder
              ? Border.all(
                  color: labelColor,
                  width: 1,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color indicator dot
            if (showBorder)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: labelColor,
                  shape: BoxShape.circle,
                ),
                margin: const EdgeInsets.only(right: AppSpacing.xs),
              ),
            // Label name
            Text(
              label.name,
              style: AppTypography.captionSmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calculate contrasting text color (black or white)
  Color _getContrastingTextColor(Color backgroundColor) {
    // Calculate luminance
    final luminance = backgroundColor.computeLuminance();
    
    // Return black for light colors, white for dark colors
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
