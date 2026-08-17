import 'averaged_spectrum.dart';
import 'experiment.dart';

class ExperimentMatcher {
  ExperimentMatchResult match(Map<String, AveragedSpectrum> averages) {
    final experiments = <String, Experiment>{};
    final warnings = <String>[];

    for (final entry in averages.entries) {
      final groupKey = entry.key;
      final averaged = entry.value;

      final key = averaged.meta.substanceTimeKey.isNotEmpty
          ? averaged.meta.substanceTimeKey
          : groupKey;

      final experiment = experiments.putIfAbsent(
        key,
        () => Experiment(),
      );

      if (averaged.meta.isBackground) {
        if (experiment.background != null) {
          warnings.add(
            "Найдено несколько фонов для ключа '$key'. Используется первый.",
          );
        } else {
          experiment.background = averaged;
        }
      } else {
        experiment.sources.add(averaged);
      }
    }

    return ExperimentMatchResult(
      experiments: experiments,
      warnings: warnings,
    );
  }
}