import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/models.dart';

class SpectrumFileWriter {
  Future<void> write(String path, SpectrumData data) async {
    final directory = p.dirname(path);

    if (directory.isNotEmpty) {
      await Directory(directory).create(recursive: true);
    }

    final buffer = StringBuffer();

    for (var i = 0; i < data.channels.length; i++) {
      final channel = data.channels[i].round();
      final count = data.counts[i].toStringAsFixed(6);

      buffer.writeln('$channel\t$count');
    }

    await File(path).writeAsString(
      buffer.toString(),
      flush: true,
    );
  }
}