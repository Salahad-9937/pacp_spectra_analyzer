import 'package:flutter/material.dart';

import '../theme.dart';

class AppToolbar extends StatelessWidget {
  const AppToolbar({
    super.key,
    required this.directory,
    required this.busy,
    required this.onChooseDirectory,
    required this.onRefresh,
    required this.onProcess,
    required this.onClearSelection,
  });

  final String? directory;
  final bool busy;
  final VoidCallback onChooseDirectory;
  final VoidCallback onRefresh;
  final VoidCallback onProcess;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: busy ? null : onChooseDirectory,
            icon: const Icon(Icons.folder_open, size: 17),
            label: const Text('Выбрать директорию'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : onRefresh,
            icon: const Icon(Icons.refresh, size: 17),
            label: const Text('Обновить'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: busy ? null : onProcess,
            icon: busy
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.analytics, size: 17),
            label: const Text('Обработать спектры'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: busy ? null : onClearSelection,
            icon: const Icon(Icons.clear_all, size: 17),
            label: const Text('Снять выбор'),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Tooltip(
              message: directory ?? 'Директория не выбрана',
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
                        directory ?? 'Директория не выбрана',
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
            ),
          ),
        ],
      ),
    );
  }
}