import '../../domain/models.dart';
import 'spectrum_loader.dart';

class CachedSpectrumLoader implements SpectrumLoader {
  CachedSpectrumLoader(this._loader);

  final SpectrumLoader _loader;
  final Map<String, Future<SpectrumData>> _cache = {};

  @override
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