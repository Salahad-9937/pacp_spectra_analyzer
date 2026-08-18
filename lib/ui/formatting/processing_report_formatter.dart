import 'package:path/path.dart' as p;

import '../../domain/models.dart';

class ProcessingReportFormatter {
  String summary(ProcessingReport report) {
    return _summaryLines(report).join('\n');
  }

  String details(ProcessingReport report) {
    final details = List<String>.from(_summaryLines(report));

    if (report.createdAverageFiles.isNotEmpty) {
      details.add('');
      details.add('Созданные средние файлы:');
      for (final path in report.createdAverageFiles) {
        details.add('  - ${p.basename(path)}');
      }
    }

    if (report.createdSumFiles.isNotEmpty) {
      details.add('');
      details.add('Созданные файлы суммы:');
      for (final path in report.createdSumFiles) {
        details.add('  - ${p.basename(path)}');
      }
    }

    if (report.createdDifferenceFiles.isNotEmpty) {
      details.add('');
      details.add('Созданные файлы без фона:');
      for (final path in report.createdDifferenceFiles) {
        details.add('  - ${p.basename(path)}');
      }
    }

    if (report.warnings.isNotEmpty) {
      details.add('');
      details.add('Предупреждения:');
      for (final warning in report.warnings) {
        details.add('  ! $warning');
      }
    }

    return details.join('\n');
  }

  List<String> _summaryLines(ProcessingReport report) {
    final summary = [
      'Обработка завершена.',
      'Обработано файлов: ${report.processedFiles}',
      'Пропущено пустых шаблонов: ${report.skippedEmptyFiles}',
      'Создано средних файлов: ${report.createdAverageFiles.length}',
      'Создано файлов суммы: ${report.createdSumFiles.length}',
      'Создано файлов без фона: ${report.createdDifferenceFiles.length}',
    ];

    if (report.warnings.isNotEmpty) {
      summary.add('Предупреждений: ${report.warnings.length}');
    }

    return summary;
  }
}