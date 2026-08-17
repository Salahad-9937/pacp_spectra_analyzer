import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;

import '../../domain/models.dart';
import '../io/spectrum_file_writer.dart';
import '../loading/spectrum_loader.dart';
import 'background_subtractor.dart';
import 'generated_file_namer.dart';
import 'spectrum_averager.dart';
import 'spectrum_summator.dart';

class ManualSpectrumProcessor {
  ManualSpectrumProcessor({
    required this.loader,
    required this.writer,
    required this.averager,
    required this.summator,
    required this.subtractor,
    required this.fileNamer,
  });

  final SpectrumLoader loader;
  final SpectrumWriter writer;
  final SpectrumAverager averager;
  final SpectrumSummator summator;
  final BackgroundSubtractor subtractor;
  final GeneratedFileNamer fileNamer;

  Future<ProcessingReport> run({
    required String directory,
    required ManualOperation operation,
    required List<SpectrumMeta> selected,
    SpectrumMeta? background,
    bool skipEmpty = true,
  }) async {
    final report = ProcessingReport();

    if (directory.isEmpty) {
      report.addWarning('Директория для обработки не указана.');
      return report;
    }

    if (selected.isEmpty) {
      report.addWarning('Не выбраны файлы для обработки.');
      return report;
    }

    switch (operation) {
      case ManualOperation.average:
      case ManualOperation.sum:
        await _aggregate(
          directory: directory,
          operation: operation,
          selected: selected,
          report: report,
          skipEmpty: skipEmpty,
        );
        break;

      case ManualOperation.subtractBackground:
        await _subtractBackground(
          directory: directory,
          selected: selected,
          background: background,
          report: report,
          skipEmpty: skipEmpty,
        );
        break;
    }

    return report;
  }

  Future<void> _aggregate({
    required String directory,
    required ManualOperation operation,
    required List<SpectrumMeta> selected,
    required ProcessingReport report,
    required bool skipEmpty,
  }) async {
    final data = await _load(
      selected,
      report: report,
      skipEmpty: skipEmpty,
    );

    if (data.isEmpty) {
      report.addWarning(
        'Нет валидных ненулевых файлов для выполнения операции.',
      );
      return;
    }

    final minLen = data.fold<int>(
      data.first.counts.length,
      (prev, element) => math.min(prev, element.counts.length),
    );

    if (data.any((d) => d.counts.length != minLen)) {
      report.addWarning(
        'Длины выбранных спектров отличаются. '
        'Результат будет обрезан до $minLen каналов.',
      );
    }

    final SpectrumData result;
    final String fileName;

    if (operation == ManualOperation.average) {
      result = averager.average(data);
      fileName = fileNamer.averageFileName(_outputLabel(selected));
    } else {
      result = summator.sum(data);
      fileName = fileNamer.sumFileName(_outputLabel(selected));
    }

    final path = await _uniquePath(directory, fileName);
    await writer.write(path, result);

    if (operation == ManualOperation.average) {
      report.createdAverageFiles.add(path);
    } else {
      report.createdSumFiles.add(path);
    }
  }

  Future<void> _subtractBackground({
    required String directory,
    required List<SpectrumMeta> selected,
    required SpectrumMeta? background,
    required ProcessingReport report,
    required bool skipEmpty,
  }) async {
    if (background == null) {
      report.addWarning(
        'Для вычитания фона необходимо выбрать фоновый файл.',
      );
      return;
    }

    final sources = selected
        .where((meta) => meta.path != background.path)
        .toList();

    if (sources.isEmpty) {
      report.addWarning(
        'Выбран только фоновый файл. '
        'Отметьте хотя бы один спектр-источник.',
      );
      return;
    }

    final SpectrumData backgroundData;

    try {
      backgroundData = await loader.load(background.path);
    } catch (error) {
      report.addWarning(
        "Не удалось прочитать фоновый файл '${background.filename}': $error",
      );
      return;
    }

    if (backgroundData.allZero) {
      report.addWarning(
        "Фоновый файл '${background.filename}' похож на пустой шаблон.",
      );
    }

    var lengthWarningShown = false;

    for (final source in sources) {
      try {
        final sourceData = await loader.load(source.path);

        if (skipEmpty && sourceData.allZero) {
          report.skippedEmptyFiles++;
          continue;
        }

        if (!lengthWarningShown &&
            sourceData.counts.length != backgroundData.counts.length) {
          report.addWarning(
            'Длины источника и фона отличаются. '
            'Вычитание выполняется по минимальной длине.',
          );
          lengthWarningShown = true;
        }

        final differenceData = subtractor.subtract(
          sourceData,
          backgroundData,
        );

        final fileName = fileNamer.differenceFileName(
          source: source.source,
          substance: source.substance,
          timeText: source.timeText,
          fallback: _outputLabel([source]),
        );

        final path = await _uniquePath(directory, fileName);
        await writer.write(path, differenceData);

        report.createdDifferenceFiles.add(path);
        report.processedFiles++;
      } catch (error) {
        report.addWarning(
          "Не удалось вычесть фон для файла '${source.filename}': $error",
        );
      }
    }
  }

  Future<List<SpectrumData>> _load(
    List<SpectrumMeta> metas, {
    required ProcessingReport report,
    required bool skipEmpty,
  }) async {
    final result = <SpectrumData>[];

    for (final meta in metas) {
      try {
        final data = await loader.load(meta.path);

        if (skipEmpty && data.allZero) {
          report.skippedEmptyFiles++;
          continue;
        }

        result.add(data);
        report.processedFiles++;
      } catch (error) {
        report.addWarning(
          "Не удалось прочитать файл '${meta.filename}': $error",
        );
      }
    }

    return result;
  }

  String _outputLabel(List<SpectrumMeta> selected) {
    if (selected.isEmpty) {
      return 'результат';
    }

    if (selected.length == 1) {
      final meta = selected.first;
      final parts = <String>[];

      if (meta.source.isNotEmpty &&
          meta.source != '?' &&
          meta.source != '—') {
        parts.add(meta.source);
      }

      if (meta.substance.isNotEmpty) {
        parts.add(meta.substance);
      }

      if (meta.timeText.isNotEmpty) {
        parts.add(meta.timeText);
      }

      final label = parts.join(' ').trim();

      return label.isEmpty
          ? p.withoutExtension(meta.filename)
          : label;
    }

    return 'выбрано_${selected.length}';
  }

  Future<String> _uniquePath(String directory, String fileName) async {
    var candidate = p.join(directory, fileName);

    if (!await File(candidate).exists()) {
      return candidate;
    }

    final stem = p.withoutExtension(fileName);
    final extension = p.extension(fileName);
    var counter = 1;

    while (true) {
      candidate = p.join(
        directory,
        '${stem}_$counter$extension',
      );

      if (!await File(candidate).exists()) {
        return candidate;
      }

      counter++;
    }
  }
}