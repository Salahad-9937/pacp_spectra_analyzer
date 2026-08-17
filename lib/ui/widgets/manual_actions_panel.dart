import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../theme.dart';
import 'panel_card.dart';

class ManualActionsPanel extends StatelessWidget {
  const ManualActionsPanel({
    super.key,
    required this.operation,
    required this.onOperationChanged,
    required this.items,
    required this.backgroundPath,
    required this.onBackgroundChanged,
    required this.selectedCount,
    required this.skipEmpty,
    required this.onSkipEmptyChanged,
    required this.clampNegative,
    required this.onClampNegativeChanged,
    required this.canRun,
    required this.busy,
    required this.onRun,
  });

  final ManualOperation operation;
  final ValueChanged<ManualOperation> onOperationChanged;

  final List<SpectrumMeta> items;
  final String? backgroundPath;
  final ValueChanged<String?> onBackgroundChanged;

  final int selectedCount;
  final bool skipEmpty;
  final ValueChanged<bool> onSkipEmptyChanged;

  final bool clampNegative;
  final ValueChanged<bool> onClampNegativeChanged;

  final bool canRun;
  final bool busy;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final effectiveBackground = backgroundPath != null &&
            items.any((item) => item.path == backgroundPath)
        ? backgroundPath
        : null;

    return PanelCard(
      title: 'Менеджер обработки',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Выбрано файлов: $selectedCount',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Material(
              type: MaterialType.transparency,
              child: DropdownButtonFormField<ManualOperation>(
                initialValue: operation,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Операция',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: ManualOperation.values
                    .map(
                      (op) => DropdownMenuItem(
                        value: op,
                        child: Text(op.label),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) {
                        if (value != null) {
                          onOperationChanged(value);
                        }
                      },
              ),
            ),
            if (operation == ManualOperation.subtractBackground) ...[
              const SizedBox(height: 10),
              Material(
                type: MaterialType.transparency,
                child: DropdownButtonFormField<String?>(
                  initialValue: effectiveBackground,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Фоновый файл',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Не выбран'),
                    ),
                    ...items.map(
                      (meta) => DropdownMenuItem<String?>(
                        value: meta.path,
                        child: Text(
                          meta.shortLabel,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: busy ? null : onBackgroundChanged,
                ),
              ),
              const SizedBox(height: 6),
              Material(
                type: MaterialType.transparency,
                child: CheckboxListTile(
                  value: clampNegative,
                  onChanged: busy
                      ? null
                      : (value) {
                          onClampNegativeChanged(value ?? true);
                        },
                  title: const Text('Обнулять отрицательные значения'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Material(
              type: MaterialType.transparency,
              child: CheckboxListTile(
                value: skipEmpty,
                onChanged: busy
                    ? null
                    : (value) {
                        onSkipEmptyChanged(value ?? false);
                      },
                title: const Text('Пропускать пустые файлы'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: canRun && !busy ? onRun : null,
              icon: busy
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.play_arrow, size: 17),
              label: Text('Выполнить: ${operation.label}'),
            ),
          ],
        ),
      ),
    );
  }
}