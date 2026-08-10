import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../domain/models.dart';
import 'file_scanner.dart';
import 'spectrum_loader.dart';
import 'spectrum_writer.dart';

class _AverageEntry {
  final SpectrumMeta meta;
  final SpectrumData data;

  _AverageEntry(this.meta, this.data);
}

class _Experiment {
  _AverageEntry? background;
  final List<_AverageEntry> sources = [];
}

class SpectrumProcessor {
  static const String avgPrefix = 'Среднее_';
  static const String resPrefix = 'Результат (без фона)_';

  final SpectrumFileScanner scanner;
  final SpectrumDataLoader loader;
  final SpectrumFileWriter writer;

  SpectrumProcessor({
    required this.scanner,
    required this.loader,
    required this.writer,
  });

  Future<ProcessingReport> processDirectory(String directory) async {
    final report = ProcessingReport();

    if (directory.isEmpty) {
      report.warnings.add('Директория для обработки не найдена.');
      return report;
    }

    final dir = Directory(directory);

    if (!await dir.exists()) {
      report.warnings.add('Директория для обработки не найдена.');
      return report;
    }

    final metas = await scanner.scan(directory);

    final originalMetas = metas
        .where((meta) => meta.kind == SpectrumKind.original)
        .toList();

    final groups = <String, List<SpectrumMeta>>{};

    for (final meta in originalMetas) {
      if (meta.groupKey.isNotEmpty) {
        groups.putIfAbsent(meta.groupKey, () => []).add(meta);
      }
    }

    final averages = <String, _AverageEntry>{};

    for (final group in groups.entries) {
      final groupKey = group.key;
      final groupMetas = group.value;
      final validData = <SpectrumData>[];

      for (final meta in groupMetas) {
        try {
          final data = await loader.load(meta.path);

          if (data.allZero) {
            report.skippedEmptyFiles++;
            continue;
          }

          validData.add(data);
          report.processedFiles++;
        } catch (error) {
          report.warnings.add(
            "Не удалось прочитать файл '${meta.filename}': $error",
          );
        }
      }

      if (validData.isEmpty) {
        report.warnings.add(
          "Группа '$groupKey' пропущена: нет валидных ненулевых измерений.",
        );
        continue;
      }

      try {
        final averageData = _average(validData);

        final averageFilename = _sanitizeFilename(
          '$avgPrefix$groupKey.txt',
        );

        final averagePath = p.join(directory, averageFilename);

        await writer.write(averagePath, averageData);

        report.createdAverageFiles.add(averagePath);

        averages[groupKey] = _AverageEntry(
          groupMetas.first,
          averageData,
        );
      } catch (error) {
        report.warnings.add(
          "Не удалось обработать группу '$groupKey': $error",
        );
      }
    }

    final experiments = <String, _Experiment>{};

    for (final average in averages.entries) {
      final groupKey = average.key;
      final entry = average.value;

      final key = entry.meta.substanceTimeKey.isNotEmpty
          ? entry.meta.substanceTimeKey
          : groupKey;

      final experiment = experiments.putIfAbsent(
        key,
        () => _Experiment(),
      );

      if (entry.meta.isBackground) {
        if (experiment.background != null) {
          report.warnings.add(
            "Найдено несколько фонов для ключа '$key'. Используется первый.",
          );
        } else {
          experiment.background = entry;
        }
      } else {
        experiment.sources.add(entry);
      }
    }

    for (final experimentEntry in experiments.entries) {
      final key = experimentEntry.key;
      final experiment = experimentEntry.value;

      if (experiment.sources.isEmpty) {
        continue;
      }

      final background = experiment.background;

      if (background == null) {
        for (final source in experiment.sources) {
          report.warnings.add(
            "Для источника '${source.meta.source} ${source.meta.substance} "
            "${source.meta.timeText}' не найден фон по ключу '$key'.",
          );
        }

        continue;
      }

      for (final source in experiment.sources) {
        try {
          final differenceData = _subtract(source.data, background.data);

          final resultParts = <String>[];

          if (source.meta.source.isNotEmpty &&
              source.meta.source != '?' &&
              source.meta.source != '—') {
            resultParts.add(source.meta.source);
          }

          if (source.meta.substance.isNotEmpty) {
            resultParts.add(source.meta.substance);
          }

          if (source.meta.timeText.isNotEmpty) {
            resultParts.add(source.meta.timeText);
          }

          final resultBase = resultParts.join(' ').trim();
          final baseName = resultBase.isNotEmpty ? resultBase : key;

          final resultFilename = _sanitizeFilename(
            '$resPrefix$baseName.txt',
          );

          final resultPath = p.join(directory, resultFilename);

          await writer.write(resultPath, differenceData);

          report.createdDifferenceFiles.add(resultPath);
        } catch (error) {
          report.warnings.add(
            "Не удалось вычесть фон для источника '${source.meta.filename}': $error",
          );
        }
      }
    }

    return report;
  }

  SpectrumData _average(List<SpectrumData> dataList) {
    if (dataList.isEmpty) {
      throw ArgumentError('Нет данных для усреднения.');
    }

    var minLen = dataList.first.counts.length;

    for (final data in dataList) {
      minLen = min(minLen, data.counts.length);
    }

    final channels = Float64List.fromList(
      dataList.first.channels.sublist(0, minLen),
    );

    final counts = Float64List(minLen);

    for (final data in dataList) {
      for (var i = 0; i < minLen; i++) {
        counts[i] += data.counts[i];
      }
    }

    for (var i = 0; i < minLen; i++) {
      counts[i] /= dataList.length;
    }

    return SpectrumData.fromArrays(channels, counts);
  }

  SpectrumData _subtract(SpectrumData source, SpectrumData background) {
    final minLen = min(source.counts.length, background.counts.length);

    final channels = Float64List.fromList(
      source.channels.sublist(0, minLen),
    );

    final counts = Float64List(minLen);

    for (var i = 0; i < minLen; i++) {
      // Отрицательных отсчётов быть не может:
      // всё, что ниже нуля после вычитания фона, обнуляется.
      final diff = source.counts[i] - background.counts[i];
      counts[i] = diff < 0 ? 0 : diff;
    }

    return SpectrumData.fromArrays(channels, counts);
  }

  String _sanitizeFilename(String name) {
    var result = name;

    const invalid = r'<>:"/\|?*';

    for (final char in invalid.split('')) {
      result = result.replaceAll(char, '_');
    }

    result = result.trim();

    while (result.endsWith('.')) {
      result = result.substring(0, result.length - 1);
    }

    return result.isEmpty ? 'spectrum.txt' : result;
  }
}