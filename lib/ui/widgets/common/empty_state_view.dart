import 'package:flutter/material.dart';

import '../../theme.dart';

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    this.icon,
    required this.message,
    this.iconSize = 42,
  });

  final IconData? icon;
  final String message;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: iconSize,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}