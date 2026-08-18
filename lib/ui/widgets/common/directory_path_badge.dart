import 'package:flutter/material.dart';

import '../../theme.dart';

class DirectoryPathBadge extends StatelessWidget {
  const DirectoryPathBadge({
    super.key,
    required this.directory,
  });

  final String? directory;

  @override
  Widget build(BuildContext context) {
    final text = directory ?? 'Директория не выбрана';

    return Tooltip(
      message: text,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F6FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.folder,
              size: 15,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}