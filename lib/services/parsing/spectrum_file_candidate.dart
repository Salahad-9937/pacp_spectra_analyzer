import 'spectrum_generated_prefixes.dart';

class SpectrumFileCandidate {
  final RegExp _suffixRe = RegExp(r'^(?<base>.+?)_(?<n1>\d+)_(?<n2>\d+)$');

  bool isCandidate(String filename) {
    final lower = filename.toLowerCase();

    if (!lower.endsWith('.txt')) {
      return false;
    }

    if (lower.startsWith('параметры')) {
      return false;
    }

    final stem = filename.substring(0, filename.length - 4);

    return _suffixRe.firstMatch(stem) != null ||
        filename.startsWith(SpectrumGeneratedPrefixes.average) ||
        filename.startsWith(SpectrumGeneratedPrefixes.difference);
  }
}