import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/models.dart';
import 'file_name_parser.dart';

class SpectrumFileScanner {
  final FileNameParser parser;

  SpectrumFileScanner(this.parser);

  Future<List<SpectrumMeta>> scan(String directory) async {
    if (directory.isEmpty) {
      return [];
    }

    final dir = Directory(directory);

    if (!await dir.exists()) {
      return [];
    }

    final result = <SpectrumMeta>[];

    try {
      await for (final entity in dir.list()) {
        if (entity is! File) {
          continue;
        }

        final filename = p.basename(entity.path);

        if (!parser.isCandidate(filename)) {
          continue;
        }

        result.add(parser.parse(entity.path));
      }
    } catch (_) {
      return result;
    }

    result.sort(
      (a, b) => a.filename.toLowerCase().compareTo(b.filename.toLowerCase()),
    );

    return result;
  }
}