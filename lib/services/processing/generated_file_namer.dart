import '../../core/file_name_sanitizer.dart';
import '../parsing/spectrum_generated_prefixes.dart';

class GeneratedFileNamer {
  GeneratedFileNamer({FileNameSanitizer? sanitizer})
      : _sanitizer = sanitizer ?? FileNameSanitizer();

  final FileNameSanitizer _sanitizer;

  String averageFileName(String groupKey) {
    return _sanitizer.sanitize(
      '${SpectrumGeneratedPrefixes.average}$groupKey.txt',
    );
  }

  String differenceFileName({
    required String source,
    required String substance,
    required String timeText,
    required String fallback,
  }) {
    final parts = <String>[];

    if (source.isNotEmpty && source != '?' && source != '—') {
      parts.add(source);
    }

    if (substance.isNotEmpty) {
      parts.add(substance);
    }

    if (timeText.isNotEmpty) {
      parts.add(timeText);
    }

    final base = parts.join(' ').trim();
    final name = base.isNotEmpty ? base : fallback;

    return _sanitizer.sanitize(
      '${SpectrumGeneratedPrefixes.difference}$name.txt',
    );
  }
}