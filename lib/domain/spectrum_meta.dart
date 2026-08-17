import 'spectrum_kind.dart';

class SpectrumMeta {
  final String path;
  final String filename;
  final SpectrumKind kind;
  final bool isGenerated;
  final String source;
  final String substance;
  final String timeText;
  final double? minutes;
  final String shortLabel;
  final String groupKey;
  final String substanceTimeKey;
  final bool isBackground;

  const SpectrumMeta({
    required this.path,
    required this.filename,
    required this.kind,
    required this.isGenerated,
    required this.source,
    required this.substance,
    required this.timeText,
    required this.minutes,
    required this.shortLabel,
    required this.groupKey,
    required this.substanceTimeKey,
    required this.isBackground,
  });
}