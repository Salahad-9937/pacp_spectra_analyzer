import '../../domain/models.dart';

class SpectrumKindLabels {
  const SpectrumKindLabels._();

  static String of(SpectrumKind kind) {
    switch (kind) {
      case SpectrumKind.original:
        return 'Исходное измерение';
      case SpectrumKind.average:
        return 'Среднее значение (создано программой)';
      case SpectrumKind.sum:
        return 'Сумма (создано программой)';
      case SpectrumKind.difference:
        return 'Разность без фона (создано программой)';
      case SpectrumKind.unknown:
        return 'Неизвестный файл';
    }
  }
}