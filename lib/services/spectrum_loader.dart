import 'dart:convert';
import 'dart:io';

import '../domain/models.dart';

class SpectrumDataLoader {
  Future<SpectrumData> load(String path) async {
    final file = File(path);

    if (!await file.exists()) {
      throw StateError('Файл не найден: $path');
    }

    final bytes = await file.readAsBytes();
    final text = utf8.decode(bytes, allowMalformed: true);

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

class CachedSpectrumLoader {
  final SpectrumDataLoader _loader;
  final Map<String, Future<SpectrumData>> _cache = {};

  CachedSpectrumLoader(this._loader);

  Future<SpectrumData> load(String path) async {
    final existing = _cache[path];

    if (existing != null) {
      return existing;
    }

    final future = _loader.load(path);
    _cache[path] = future;

    try {
      return await future;
    } catch (_) {
      _cache.remove(path);
      rethrow;
    }
  }

  void invalidate() {
    _cache.clear();
  }
}