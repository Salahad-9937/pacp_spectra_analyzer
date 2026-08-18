import 'package:flutter/foundation.dart';

import '../../domain/models.dart';
import '../../services/io/spectrum_file_scanner.dart';
import '../../services/loading/cached_spectrum_loader.dart';
import '../../services/processing/manual_spectrum_processor.dart';
import '../../services/processing/spectrum_processor.dart';
import '../formatting/processing_report_formatter.dart';
import '../formatting/spectrum_info_formatter.dart';
import '../loading/plot_curve_loader.dart';
import '../services/directory_picker.dart';
import '../widgets/spectrum_chart.dart';
import 'workspace_warning.dart';

class SpectrumWorkspaceController extends ChangeNotifier {
  SpectrumWorkspaceController({
    required DirectoryPicker directoryPicker,
    required SpectrumFileScanner scanner,
    required CachedSpectrumLoader loader,
    required SpectrumProcessor processor,
    required ManualSpectrumProcessor manualProcessor,
    required PlotCurveLoader curveLoader,
    required SpectrumInfoFormatter infoFormatter,
    required ProcessingReportFormatter reportFormatter,
  })  : _directoryPicker = directoryPicker,
        _scanner = scanner,
        _loader = loader,
        _processor = processor,
        _manualProcessor = manualProcessor,
        _curveLoader = curveLoader,
        _infoFormatter = infoFormatter,
        _reportFormatter = reportFormatter;

  final DirectoryPicker _directoryPicker;
  final SpectrumFileScanner _scanner;
  final CachedSpectrumLoader _loader;
  final SpectrumProcessor _processor;
  final ManualSpectrumProcessor _manualProcessor;
  final PlotCurveLoader _curveLoader;
  final SpectrumInfoFormatter _infoFormatter;
  final ProcessingReportFormatter _reportFormatter;

  bool _disposed = false;

  String? _currentDirectory;
  List<SpectrumMeta> _items = [];
  Map<String, SpectrumMeta> _itemsByPath = {};
  final Set<String> _selectedPaths = {};
  List<PlotCurve> _plotCurves = [];

  String _infoText =
      'Нажмите «Выбрать директорию», чтобы начать работу.';

  bool _processing = false;
  bool _loading = false;

  ManualOperation _manualOperation = ManualOperation.average;
  String? _backgroundPath;
  bool _skipEmpty = true;
  bool _clampNegative = true;

  String? get currentDirectory => _currentDirectory;
  List<SpectrumMeta> get items => _items;
  Set<String> get selectedPaths => Set.unmodifiable(_selectedPaths);
  int get selectedCount => _selectedPaths.length;
  List<PlotCurve> get plotCurves => _plotCurves;
  String get infoText => _infoText;

  bool get loading => _loading;
  bool get processing => _processing;
  bool get busy => _loading || _processing;

  ManualOperation get manualOperation => _manualOperation;
  String? get backgroundPath => _backgroundPath;
  bool get skipEmpty => _skipEmpty;
  bool get clampNegative => _clampNegative;

  bool get canRunManual {
    if (_currentDirectory == null) {
      return false;
    }

    if (_selectedPaths.isEmpty) {
      return false;
    }

    if (_manualOperation == ManualOperation.subtractBackground) {
      final background = _backgroundPath;
      if (background == null || !_itemsByPath.containsKey(background)) {
        return false;
      }

      return _selectedPaths.any((path) => path != background);
    }

    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> chooseDirectory() async {
    final directory = await _directoryPicker.pickDirectory(
      dialogTitle: 'Выберите рабочую директорию',
    );

    if (directory == null || directory.isEmpty) {
      return;
    }

    _currentDirectory = directory;
    _selectedPaths.clear();
    _plotCurves = [];
    _backgroundPath = null;
    _infoText = 'Директория выбрана. Выполняется обновление...';
    _notify();

    await refresh();
  }

  Future<void> refresh() async {
    final directory = _currentDirectory;

    if (directory == null) {
      _items = [];
      _itemsByPath = {};
      _plotCurves = [];
      _infoText = 'Директория не выбрана.';
      _notify();
      return;
    }

    _setLoading(true);
    _loader.invalidate();

    try {
      final metas = await _scanner.scan(directory);

      final byPath = <String, SpectrumMeta>{
        for (final meta in metas) meta.path: meta,
      };

      _selectedPaths.removeWhere((path) => !byPath.containsKey(path));

      final backgroundPath = _backgroundPath;
      if (backgroundPath != null && !byPath.containsKey(backgroundPath)) {
        _backgroundPath = null;
      }

      final curves = await _curveLoader.load(metas, _selectedPaths);

      _items = metas;
      _itemsByPath = byPath;
      _plotCurves = curves;

      if (_items.isEmpty) {
        _infoText = 'В выбранной директории не найдено подходящих файлов.';
      } else {
        _infoText = 'Кликните по названию файла, чтобы посмотреть информацию. '
            'Чекбокс добавляет файл на график.';
      }

      _notify();
    } catch (error) {
      _items = [];
      _itemsByPath = {};
      _plotCurves = [];
      _notify();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<ProcessingReport> processSpectra() async {
    final directory = _currentDirectory;

    if (directory == null) {
      throw const WorkspaceWarning(
        'Обработка спектров',
        'Сначала выберите директорию.',
      );
    }

    if (_processing) {
      throw const WorkspaceWarning(
        'Обработка спектров',
        'Обработка уже выполняется.',
      );
    }

    _setProcessing(true);
    _loader.invalidate();

    try {
      final report = await _processor.processDirectory(directory);

      _loader.invalidate();
      await refresh();
      _applyReport(report);

      return report;
    } finally {
      _setProcessing(false);
    }
  }

  Future<ProcessingReport> runManualProcessing() async {
    final directory = _currentDirectory;

    if (directory == null) {
      throw const WorkspaceWarning(
        'Менеджер обработки',
        'Сначала выберите директорию.',
      );
    }

    if (_processing) {
      throw const WorkspaceWarning(
        'Менеджер обработки',
        'Обработка уже выполняется.',
      );
    }

    if (!canRunManual) {
      throw const WorkspaceWarning(
        'Менеджер обработки',
        'Проверьте выбранные файлы и фоновый файл.',
      );
    }

    _setProcessing(true);
    _loader.invalidate();

    try {
      final selected = _selectedMetas;
      final background = _backgroundPath == null
          ? null
          : _itemsByPath[_backgroundPath];

      final report = await _manualProcessor.run(
        directory: directory,
        operation: _manualOperation,
        selected: selected,
        background: background,
        skipEmpty: _skipEmpty,
        clampNegative: _clampNegative,
      );

      _loader.invalidate();
      await refresh();
      _applyReport(report);

      return report;
    } finally {
      _setProcessing(false);
    }
  }

  Future<void> toggle(String path, bool checked) async {
    if (checked) {
      _selectedPaths.add(path);
    } else {
      _selectedPaths.remove(path);
    }

    _notify();

    await _updatePlot();
    await showInfo(path);
  }

  Future<void> showInfo(String path) async {
    final meta = _itemsByPath[path];

    if (meta == null) {
      return;
    }

    try {
      final data = await _loader.load(path);
      _infoText = _infoFormatter.format(meta, data);
    } catch (error) {
      _infoText = _infoFormatter.format(meta, null, error: '$error');
    }

    _notify();
  }

  Future<void> clearSelection() async {
    _selectedPaths.clear();
    _infoText = 'Выбор снят.';
    _notify();

    await _updatePlot();
  }

  void setManualOperation(ManualOperation value) {
    if (_manualOperation == value) {
      return;
    }

    _manualOperation = value;
    _notify();
  }

  void setBackgroundPath(String? value) {
    if (_backgroundPath == value) {
      return;
    }

    _backgroundPath = value;
    _notify();
  }

  void setSkipEmpty(bool value) {
    if (_skipEmpty == value) {
      return;
    }

    _skipEmpty = value;
    _notify();
  }

  void setClampNegative(bool value) {
    if (_clampNegative == value) {
      return;
    }

    _clampNegative = value;
    _notify();
  }

  List<SpectrumMeta> get _selectedMetas {
    return _items
        .where((meta) => _selectedPaths.contains(meta.path))
        .toList();
  }

  Future<void> _updatePlot() async {
    final curves = await _curveLoader.load(_items, _selectedPaths);
    _plotCurves = curves;
    _notify();
  }

  void _applyReport(ProcessingReport report) {
    _infoText = _reportFormatter.details(report);
    _notify();
  }

  void _setLoading(bool value) {
    if (_loading == value) {
      return;
    }

    _loading = value;
    _notify();
  }

  void _setProcessing(bool value) {
    if (_processing == value) {
      return;
    }

    _processing = value;
    _notify();
  }
}