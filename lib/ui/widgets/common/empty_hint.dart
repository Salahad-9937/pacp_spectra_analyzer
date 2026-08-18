import 'package:flutter/material.dart';

import '../../theme.dart';

class EmptyHint extends StatelessWidget {
  const EmptyHint({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 14, 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}