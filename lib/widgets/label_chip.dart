import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable label chip widget
class LabelChipWidget extends StatelessWidget {
  final String label;
  final String? colorHex;
  final double fontSize;

  const LabelChipWidget({
    super.key,
    required this.label,
    this.colorHex,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorHex != null
        ? Color(int.parse('FF$colorHex', radix: 16))
        : AppColors.orangePrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
    );
  }
}
