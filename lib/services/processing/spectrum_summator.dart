import 'dart:math';
import 'dart:typed_data';

import '../../domain/models.dart';

class SpectrumSummator {
  SpectrumData sum(List<SpectrumData> dataList) {
    if (dataList.isEmpty) {
      throw ArgumentError('Нет данных для суммирования.');
    }

    var minLen = dataList.first.counts.length;

    for (final data in dataList) {
      minLen = min(minLen, data.counts.length);
    }

    final channels = Float64List.fromList(
      dataList.first.channels.sublist(0, minLen),
    );

    final counts = Float64List(minLen);

    for (final data in dataList) {
      for (var i = 0; i < minLen; i++) {
        counts[i] += data.counts[i];
      }
    }

    return SpectrumData.fromArrays(channels, counts);
  }
}