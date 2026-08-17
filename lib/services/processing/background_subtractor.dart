import 'dart:math';
import 'dart:typed_data';

import '../../domain/models.dart';

class BackgroundSubtractor {
  SpectrumData subtract(
    SpectrumData source,
    SpectrumData background, {
    bool clampNegativeToZero = true,
  }) {
    final minLen = min(source.counts.length, background.counts.length);

    final channels = Float64List.fromList(
      source.channels.sublist(0, minLen),
    );

    final counts = Float64List(minLen);

    for (var i = 0; i < minLen; i++) {
      final diff = source.counts[i] - background.counts[i];
      counts[i] = clampNegativeToZero && diff < 0 ? 0 : diff;
    }

    return SpectrumData.fromArrays(channels, counts);
  }
}