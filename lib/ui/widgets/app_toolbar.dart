import 'package:flutter/material.dart';

import '../theme.dart';
import 'common/app_button.dart';
import 'common/directory_path_badge.dart';

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
          AppButton(
            label: 'Выбрать директорию',
            icon: Icons.folder_open,
            onPressed: busy ? null : onChooseDirectory,
          ),
          const SizedBox(width: 8),
          AppButton(
            label: 'Обновить',
            icon: Icons.refresh,
            onPressed: busy ? null : onRefresh,
          ),
          const SizedBox(width: 8),
          AppButton(
            kind: AppButtonKind.elevated,
            label: 'Обработать спектры',
            icon: Icons.analytics,
            busy: busy,
            showBusyIndicator: true,
            onPressed: busy ? null : onProcess,
          ),
          const SizedBox(width: 8),
          AppButton(
            kind: AppButtonKind.text,
            label: 'Снять выбор',
            icon: Icons.clear_all,
            onPressed: busy ? null : onClearSelection,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: DirectoryPathBadge(directory: directory),
          ),
        ],
      ),
    );
  }
}