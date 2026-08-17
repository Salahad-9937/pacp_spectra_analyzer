import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/models.dart';

abstract class SpectrumWriter {
  Future<void> write(String path, SpectrumData data);
}

class SpectrumDataFormatter {
  String format(SpectrumData data) {
    final buffer = StringBuffer();

    for (var i = 0; i < data.channels.length; i++) {
      final channel = data.channels[i].round();
      final count = data.counts[i].toStringAsFixed(6);

      buffer.writeln('$channel\t$count');
    }

    return buffer.toString();
  }
}

class SpectrumFileWriter implements SpectrumWriter {
  SpectrumFileWriter({SpectrumDataFormatter? formatter})
      : _formatter = formatter ?? SpectrumDataFormatter();

  final SpectrumDataFormatter _formatter;

  @override
  Future<void> write(String path, SpectrumData data) async {
    final directory = p.dirname(path);

    if (directory.isNotEmpty) {
      await Directory(directory).create(recursive: true);
    }

    await File(path).writeAsString(
      _formatter.format(data),
      flush: true,
    );
  }
}