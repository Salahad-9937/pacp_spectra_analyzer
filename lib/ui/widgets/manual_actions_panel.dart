import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../theme.dart';
import 'common/app_button.dart';
import 'common/compact_checkbox_tile.dart';
import 'common/labeled_dropdown.dart';
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
            LabeledDropdown<ManualOperation>(
              label: 'Операция',
              value: operation,
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
            if (operation == ManualOperation.subtractBackground) ...[
              const SizedBox(height: 10),
              LabeledDropdown<String?>(
                label: 'Фоновый файл',
                value: effectiveBackground,
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
              const SizedBox(height: 6),
              CompactCheckboxTile(
                title: 'Обнулять отрицательные значения',
                value: clampNegative,
                onChanged: onClampNegativeChanged,
                enabled: !busy,
              ),
            ],
            const SizedBox(height: 6),
            CompactCheckboxTile(
              title: 'Пропускать пустые файлы',
              value: skipEmpty,
              onChanged: onSkipEmptyChanged,
              enabled: !busy,
            ),
            const SizedBox(height: 8),
            AppButton(
              kind: AppButtonKind.elevated,
              label: 'Выполнить: ${operation.label}',
              icon: Icons.play_arrow,
              busy: busy,
              showBusyIndicator: true,
              onPressed: canRun && !busy ? onRun : null,
            ),
          ],
        ),
      ),
    );
  }
}