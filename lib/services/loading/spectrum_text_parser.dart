import 'dart:convert';

import '../../domain/models.dart';

class SpectrumTextParser {
  SpectrumData parse(String text) {
    final channels = <double>[];
    final counts = <double>[];

    final lines = const LineSplitter().convert(text);

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        continue;
      }

      final parts = trimmed.split(RegExp(r'\s+'));

      if (parts.length < 2) {
        continue;
      }

      final channel = double.tryParse(parts[0]);
      final count = double.tryParse(parts[1]);

      if (channel == null || count == null) {
        continue;
      }

      channels.add(channel);
      counts.add(count);
    }

    if (channels.isEmpty) {
      throw StateError('Файл не содержит данных спектра.');
    }

    return SpectrumData.fromArrays(channels, counts);
  }
}