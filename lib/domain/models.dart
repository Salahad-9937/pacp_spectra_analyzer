import 'dart:typed_data';

enum SpectrumKind {
  original,
  average,
  difference,
  unknown,
}

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

class SpectrumData {
  final Float64List channels;
  final Float64List counts;
  final int channelCount;
  final double total;
  final double minCount;
  final double maxCount;
  final double minChannel;
  final double maxChannel;
  final bool allZero;

  SpectrumData._({
    required this.channels,
    required this.counts,
    required this.channelCount,
    required this.total,
    required this.minCount,
    required this.maxCount,
    required this.minChannel,
    required this.maxChannel,
    required this.allZero,
  });

  factory SpectrumData.fromArrays(List<double> channels, List<double> counts) {
    if (channels.length != counts.length) {
      throw ArgumentError('Количество каналов и отсчётов должно совпадать.');
    }

    if (channels.isEmpty) {
      throw ArgumentError('Нет данных для создания спектра.');
    }

    var maxIndex = 0;
    var minIndex = 0;
    var total = 0.0;
    var allZero = true;

    for (var i = 0; i < counts.length; i++) {
      final value = counts[i];

      total += value;

      if (value > counts[maxIndex]) {
        maxIndex = i;
      }

      if (value < counts[minIndex]) {
        minIndex = i;
      }

      if (value.abs() >= 1e-12) {
        allZero = false;
      }
    }

    return SpectrumData._(
      channels: Float64List.fromList(channels),
      counts: Float64List.fromList(counts),
      channelCount: channels.length,
      total: total,
      minCount: counts[minIndex],
      maxCount: counts[maxIndex],
      minChannel: channels[minIndex],
      maxChannel: channels[maxIndex],
      allZero: allZero,
    );
  }
}

class ProcessingReport {
  int processedFiles = 0;
  int skippedEmptyFiles = 0;

  final List<String> createdAverageFiles = [];
  final List<String> createdDifferenceFiles = [];
  final List<String> warnings = [];
}