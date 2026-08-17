import 'averaged_spectrum.dart';

class Experiment {
  AveragedSpectrum? background;
  final List<AveragedSpectrum> sources = [];
}

class ExperimentMatchResult {
  const ExperimentMatchResult({
    required this.experiments,
    required this.warnings,
  });

  final Map<String, Experiment> experiments;
  final List<String> warnings;
}