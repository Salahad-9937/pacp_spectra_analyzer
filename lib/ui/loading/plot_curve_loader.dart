import '../../domain/models.dart';
import '../../services/loading/spectrum_loader.dart';
import '../widgets/spectrum_chart.dart';

class PlotCurveLoader {
  const PlotCurveLoader(this._loader);

  final SpectrumLoader _loader;

  Future<List<PlotCurve>> load(
    Iterable<SpectrumMeta> items,
    Set<String> selectedPaths,
  ) async {
    final curves = <PlotCurve>[];

    for (final meta in items) {
      if (!selectedPaths.contains(meta.path)) {
        continue;
      }

      try {
        final data = await _loader.load(meta.path);
        curves.add(PlotCurve(meta, data));
      } catch (_) {
        continue;
      }
    }

    return curves;
  }
}