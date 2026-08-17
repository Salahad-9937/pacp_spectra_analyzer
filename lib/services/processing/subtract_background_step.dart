import 'package:path/path.dart' as p;

import '../../domain/models.dart';
import '../io/spectrum_file_writer.dart';
import 'background_subtractor.dart';
import 'experiment.dart';
import 'generated_file_namer.dart';

class SubtractBackgroundStep {
  SubtractBackgroundStep({
    required this.subtractor,
    required this.writer,
    required this.fileNamer,
  });

  final BackgroundSubtractor subtractor;
  final SpectrumWriter writer;
  final GeneratedFileNamer fileNamer;

  Future<void> execute({
    required String directory,
    required Map<String, Experiment> experiments,
    required ProcessingReport report,
  }) async {
    for (final experimentEntry in experiments.entries) {
      final key = experimentEntry.key;
      final experiment = experimentEntry.value;

      if (experiment.sources.isEmpty) {
        continue;
      }

      final background = experiment.background;

      if (background == null) {
        for (final source in experiment.sources) {
          final label = [
            source.meta.source,
            source.meta.substance,
            source.meta.timeText,
          ].where((part) => part.isNotEmpty).join(' ').trim();

          final display = label.isEmpty ? source.meta.filename : label;

          report.warnings.add(
            "Для источника '$display' не найден фон по ключу '$key'.",
          );
        }

        continue;
      }

      for (final source in experiment.sources) {
        try {
          final differenceData = subtractor.subtract(
            source.data,
            background.data,
          );

          final resultFilename = fileNamer.differenceFileName(
            source: source.meta.source,
            substance: source.meta.substance,
            timeText: source.meta.timeText,
            fallback: key,
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
  }
}