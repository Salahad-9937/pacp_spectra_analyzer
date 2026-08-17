import '../../domain/models.dart';

class AveragedSpectrum {
  const AveragedSpectrum({
    required this.meta,
    required this.data,
  });

  final SpectrumMeta meta;
  final SpectrumData data;
}