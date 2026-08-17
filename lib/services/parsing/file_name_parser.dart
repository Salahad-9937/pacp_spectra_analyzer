import 'package:path/path.dart' as p;
import '../../domain/models.dart';
import 'spectrum_file_candidate.dart';
import 'spectrum_generated_prefixes.dart';

class FileNameParser {
  FileNameParser({SpectrumFileCandidate? candidate})
      : _candidate = candidate ?? SpectrumFileCandidate();

  final SpectrumFileCandidate _candidate;
  final RegExp _suffixRe = RegExp(r'^(?<base>.+?)_(?<n1>\d+)_(?<n2>\d+)$');
  final RegExp _timeRe = RegExp(r'(\d+(?:[.,]\d+)?)');

  bool isCandidate(String filename) {
    return _candidate.isCandidate(filename);
  }

  SpectrumMeta parse(String path) {
    final filename = p.basename(path);
    final stem = filename.toLowerCase().endsWith('.txt')
        ? filename.substring(0, filename.length - 4)
        : filename;

    var kind = SpectrumKind.original;
    var suffix = '';
    var name = stem;

    if (name.startsWith(SpectrumGeneratedPrefixes.average)) {
      kind = SpectrumKind.average;
      name = name.substring(SpectrumGeneratedPrefixes.average.length);
    } else if (name.startsWith(SpectrumGeneratedPrefixes.sum)) {
      kind = SpectrumKind.sum;
      name = name.substring(SpectrumGeneratedPrefixes.sum.length);
    } else if (name.startsWith(SpectrumGeneratedPrefixes.difference)) {
      kind = SpectrumKind.difference;
      name = name
          .substring(SpectrumGeneratedPrefixes.difference.length)
          .replaceAll('_', ' ');
    }

    if (kind != SpectrumKind.difference) {
      final match = _suffixRe.firstMatch(name);
      if (match != null) {
        final base = match.namedGroup('base') ?? name;
        suffix = '_${match.namedGroup('n1')}_${match.namedGroup('n2')}';
        name = base;
      }
    }

    final base = name;
    final trimmedBase = base.trim();
    final tokens = trimmedBase.isEmpty
        ? <String>[]
        : trimmedBase.split(RegExp(r'\s+'));

    var source = '?';
    var substance = '';
    var timeText = '';
    double? minutes;
    var isBackground = false;

    if (tokens.isNotEmpty) {
      var timeIndex =
          tokens.indexWhere((token) => token.toLowerCase().contains('мин'));

      if (timeIndex == -1) {
        timeIndex = tokens.length - 1;
      }

      timeText = tokens[timeIndex];

      final timeMatch = _timeRe.firstMatch(timeText);
      if (timeMatch != null) {
        minutes = double.tryParse(
          timeMatch.group(1)!.replaceAll(',', '.'),
        );
      }

      if (kind == SpectrumKind.difference) {
        if (tokens.length >= 3) {
          source = tokens[0];
          substance = _joinRange(tokens, 1, timeIndex);
        } else {
          source = '—';
          substance = _joinRange(tokens, 0, timeIndex);
        }
        isBackground = false;
      } else {
        if (tokens[0].toLowerCase() == 'фон') {
          source = 'Фон';
          substance = _joinRange(tokens, 1, timeIndex);
          isBackground = true;
        } else {
          source = tokens[0];
          substance = _joinRange(tokens, 1, timeIndex);
          isBackground = false;
        }
      }
    }

    final groupKey = base.trim();
    final substanceTimeKey = _makeSubstanceTimeKey(substance, timeText);

    var shortLabel = _buildShortLabel(
      kind: kind,
      source: source,
      substance: substance,
      timeText: timeText,
      suffix: suffix,
    );

    if (shortLabel.isEmpty) {
      shortLabel = filename;
    }

    return SpectrumMeta(
      path: path,
      filename: filename,
      kind: kind,
      isGenerated: kind == SpectrumKind.average ||
          kind == SpectrumKind.sum ||
          kind == SpectrumKind.difference,
      source: source,
      substance: substance,
      timeText: timeText,
      minutes: minutes,
      shortLabel: shortLabel,
      groupKey: groupKey,
      substanceTimeKey: substanceTimeKey,
      isBackground: isBackground,
    );
  }

  String _joinRange(List<String> tokens, int start, int end) {
    if (start < 0) {
      start = 0;
    }

    if (end > tokens.length) {
      end = tokens.length;
    }

    if (start >= end) {
      return '';
    }

    return tokens.sublist(start, end).join(' ');
  }

  String _normalize(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return '';
    }

    return trimmed
        .split(RegExp(r'\s+'))
        .where((element) => element.isNotEmpty)
        .join(' ')
        .toLowerCase();
  }

  String _makeSubstanceTimeKey(String substance, String timeText) {
    final substanceNormalized = _normalize(substance);
    final timeNormalized = _normalize(timeText);

    if (substanceNormalized.isNotEmpty && timeNormalized.isNotEmpty) {
      return '${substanceNormalized}_$timeNormalized';
    }

    return timeNormalized.isNotEmpty ? timeNormalized : substanceNormalized;
  }

  String _buildShortLabel({
    required SpectrumKind kind,
    required String source,
    required String substance,
    required String timeText,
    required String suffix,
  }) {
    final parts = <String>[];

    if (kind == SpectrumKind.average) {
      parts.add('[Среднее]');
    } else if (kind == SpectrumKind.sum) {
      parts.add('[Сумма]');
    } else if (kind == SpectrumKind.difference) {
      parts.add('[Без фона]');
    }

    if (kind == SpectrumKind.difference) {
      if (source != '?' && source.isNotEmpty && source != '—') {
        parts.add(source);
      }
    } else {
      if (source != '?' && source.isNotEmpty) {
        parts.add(source);
      }
    }

    if (substance.isNotEmpty) {
      parts.add(substance);
    }

    if (timeText.isNotEmpty) {
      parts.add(timeText);
    }

    if (suffix.isNotEmpty) {
      parts.add(suffix);
    }

    return parts.join(' ');
  }
}