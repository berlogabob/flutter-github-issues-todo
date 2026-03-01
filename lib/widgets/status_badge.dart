import 'package:flutter/material.dart';
import '../models/item.dart';

/// Reusable status badge widget for open/closed issues
class StatusBadge extends StatelessWidget {
  final ItemStatus status;
  final double size;

  const StatusBadge({super.key, required this.status, this.size = 12.0});

  @override
  Widget build(BuildContext context) {
    final isOpen = status == ItemStatus.open;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOpen ? Colors.green : Colors.red,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
    );
  }
}
