import 'dart:convert';
import 'dart:io';

import '../../domain/models.dart';
import 'spectrum_loader.dart';
import 'spectrum_text_parser.dart';

class SpectrumFileReader implements SpectrumLoader {
  SpectrumFileReader({SpectrumTextParser? textParser})
      : _textParser = textParser ?? SpectrumTextParser();

  final SpectrumTextParser _textParser;

  @override
  Future<SpectrumData> load(String path) async {
    final file = File(path);

    if (!await file.exists()) {
      throw StateError('Файл не найден: $path');
    }

    final bytes = await file.readAsBytes();
    final text = utf8.decode(bytes, allowMalformed: true);

    return _textParser.parse(text);
  }
}