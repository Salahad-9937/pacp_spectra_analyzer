import 'package:path/path.dart' as p;

import '../../domain/models.dart';
import '../io/spectrum_file_writer.dart';
import '../loading/spectrum_loader.dart';
import 'averaged_spectrum.dart';
import 'generated_file_namer.dart';
import 'spectrum_averager.dart';

class AverageGroupsStep {
  AverageGroupsStep({
    required this.loader,
    required this.averager,
    required this.writer,
    required this.fileNamer,
  });

  final SpectrumLoader loader;
  final SpectrumAverager averager;
  final SpectrumWriter writer;
  final GeneratedFileNamer fileNamer;

  Future<Map<String, AveragedSpectrum>> execute({
    required String directory,
    required Map<String, List<SpectrumMeta>> groups,
    required ProcessingReport report,
  }) async {
    final averages = <String, AveragedSpectrum>{};

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
        final averageData = averager.average(validData);

        final averageFilename = fileNamer.averageFileName(groupKey);
        final averagePath = p.join(directory, averageFilename);

        await writer.write(averagePath, averageData);

        report.createdAverageFiles.add(averagePath);

        averages[groupKey] = AveragedSpectrum(
          meta: groupMetas.first,
          data: averageData,
        );
      } catch (error) {
        report.warnings.add(
          "Не удалось обработать группу '$groupKey': $error",
        );
      }
    }

    return averages;
  }
}