import '../../domain/models.dart';

class SpectrumGrouper {
  Map<String, List<SpectrumMeta>> groupOriginals(
    Iterable<SpectrumMeta> metas,
  ) {
    final groups = <String, List<SpectrumMeta>>{};

    for (final meta in metas) {
      if (meta.kind != SpectrumKind.original) {
        continue;
      }

      if (meta.groupKey.isEmpty) {
        continue;
      }

      groups.putIfAbsent(meta.groupKey, () => []).add(meta);
    }

    return groups;
  }
}