import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../theme.dart';
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
    final originalItems =
        items.where((item) => !item.isGenerated).toList();
    final generatedItems =
        items.where((item) => item.isGenerated).toList();

    return PanelCard(
      title: 'Файлы',
      child: items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Нет подходящих файлов',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                const _SectionHeader(text: 'Исходные файлы'),
                if (originalItems.isEmpty)
                  const _EmptyRow(text: 'Нет исходных файлов')
                else
                  ...originalItems.map(_buildRow),
                const SizedBox(height: 6),
                const _SectionHeader(text: 'Созданные программой'),
                if (generatedItems.isEmpty)
                  const _EmptyRow(text: 'Нет созданных файлов')
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 14, 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
      ),
    );
  }
}