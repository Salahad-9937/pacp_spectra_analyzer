class FileNameSanitizer {
  String sanitize(String name) {
    var result = name;

    const invalid = r'<>:"/\|?*';

    for (final char in invalid.split('')) {
      result = result.replaceAll(char, '_');
    }

    result = result.trim();

    while (result.endsWith('.')) {
      result = result.substring(0, result.length - 1);
    }

    return result.isEmpty ? 'spectrum.txt' : result;
  }
}