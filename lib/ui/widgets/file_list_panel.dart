import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../theme.dart';
import 'common/empty_hint.dart';
import 'common/empty_state_view.dart';
import 'common/section_header.dart';
import 'panel_card.dart';

class FileListPanel extends StatelessWidget {
  const FileListPanel({
    super.key,
    required this.items,
    required this.selectedPaths,
    required this.onToggle,
    required this.onInfo,
  });

  final List<SpectrumMeta> items;
  final Set<String> selectedPaths;
  final void Function(String path, bool checked) onToggle;
  final void Function(String path) onInfo;

  @override
  Widget build(BuildContext context) {
    final originalItems = items.where((item) => !item.isGenerated).toList();
    final generatedItems = items.where((item) => item.isGenerated).toList();

    return PanelCard(
      title: 'Файлы',
      child: items.isEmpty
          ? const EmptyStateView(
              icon: Icons.folder_off,
              message: 'Нет подходящих файлов',
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                const SectionHeader(text: 'Исходные файлы'),
                if (originalItems.isEmpty)
                  const EmptyHint(text: 'Нет исходных файлов')
                else
                  ...originalItems.map(_buildRow),
                const SizedBox(height: 6),
                const SectionHeader(text: 'Созданные программой'),
                if (generatedItems.isEmpty)
                  const EmptyHint(text: 'Нет созданных файлов')
                else
                  ...generatedItems.map(_buildRow),
                const SizedBox(height: 6),
              ],
            ),
    );
  }

  Widget _buildRow(SpectrumMeta meta) {
    final selected = selectedPaths.contains(meta.path);

    return Material(
      color: selected ? AppTheme.selectedRow : Colors.transparent,
      child: InkWell(
        onTap: () => onInfo(meta.path),
        hoverColor: AppTheme.hoverRow,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                onChanged: (value) => onToggle(meta.path, value ?? false),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    meta.shortLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}