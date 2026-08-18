import '../../domain/models.dart';
import 'spectrum_kind_labels.dart';

class SpectrumInfoFormatter {
  String format(
    SpectrumMeta meta,
    SpectrumData? data, {
    String? error,
  }) {
    final lines = <String>[];

    lines.add('Файл: ${meta.filename}');
    lines.add('Тип: ${SpectrumKindLabels.of(meta.kind)}');

    if (meta.kind == SpectrumKind.difference) {
      if (meta.source != '?' && meta.source.isNotEmpty && meta.source != '—') {
        lines.add('Источник: ${meta.source}');
      } else {
        lines.add('Назначение: результат вычитания фона');
      }
    } else {
      lines.add('Источник/фон: ${meta.source}');
    }

    lines.add('Вещество: ${meta.substance.isEmpty ? '—' : meta.substance}');
    lines.add('Время из имени: ${meta.timeText.isEmpty ? '—' : meta.timeText}');

    if (meta.isBackground) {
      lines.add('Это фоновое измерение.');
    }

    if (error != null) {
      lines.add('Ошибка чтения: $error');
    } else if (data != null) {
      lines.add('Каналов: ${data.channelCount}');
      lines.add('Сумма отсчётов: ${data.total.toStringAsFixed(1)}');
      lines.add(
        'Максимум: ${data.maxCount.toStringAsFixed(1)} '
        '(канал ${data.maxChannel.toStringAsFixed(0)})',
      );
      lines.add(
        'Минимум: ${data.minCount.toStringAsFixed(1)} '
        '(канал ${data.minChannel.toStringAsFixed(0)})',
      );

      if (data.allZero) {
        lines.add(
          'Похоже, файл является пустым шаблоном: второй столбец полностью нулевой.',
        );
      }
    }

    return lines.join('\n');
  }
}