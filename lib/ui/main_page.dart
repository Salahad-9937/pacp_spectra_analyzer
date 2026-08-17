import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../domain/models.dart';
import '../services/parsing/file_name_parser.dart';
import '../services/parsing/spectrum_file_candidate.dart';
import '../services/io/spectrum_file_scanner.dart';
import '../services/loading/spectrum_file_reader.dart';
import '../services/loading/cached_spectrum_loader.dart';
import '../services/loading/spectrum_text_parser.dart';
import '../services/io/spectrum_file_writer.dart';
import '../services/processing/spectrum_processor.dart';
import '../services/processing/spectrum_grouper.dart';
import '../services/processing/average_groups_step.dart';
import '../services/processing/experiment_matcher.dart';
import '../services/processing/subtract_background_step.dart';
import '../services/processing/spectrum_averager.dart';
import '../services/processing/background_subtractor.dart';
import '../services/processing/generated_file_namer.dart';

import 'theme.dart';
import 'widgets/app_toolbar.dart';
import 'widgets/file_list_panel.dart';
import 'widgets/info_panel.dart';
import 'widgets/plot_panel.dart';
import 'widgets/spectrum_chart.dart';

class SpectrumDesktopPage extends StatefulWidget {
  const SpectrumDesktopPage({super.key});

  @override
  State<SpectrumDesktopPage> createState() => _SpectrumDesktopPageState();
}

class _SpectrumDesktopPageState extends State<SpectrumDesktopPage> {
  late final FileNameParser _parser = FileNameParser(
    candidate: SpectrumFileCandidate(),
  );

  late final SpectrumFileScanner _scanner = SpectrumFileScanner(_parser);

  late final SpectrumFileReader _fileReader = SpectrumFileReader(
    textParser: SpectrumTextParser(),
  );

  late final CachedSpectrumLoader _loader = CachedSpectrumLoader(_fileReader);

  late final SpectrumFileWriter _writer = SpectrumFileWriter(
    formatter: SpectrumDataFormatter(),
  );

  late final GeneratedFileNamer _fileNamer = GeneratedFileNamer();

  late final SpectrumProcessor _processor = SpectrumProcessor(
    scanner: _scanner,
    grouper: SpectrumGrouper(),
    averageStep: AverageGroupsStep(
      loader: _fileReader,
      averager: SpectrumAverager(),
      writer: _writer,
      fileNamer: _fileNamer,
    ),
    experimentMatcher: ExperimentMatcher(),
    subtractStep: SubtractBackgroundStep(
      subtractor: BackgroundSubtractor(),
      writer: _writer,
      fileNamer: _fileNamer,
    ),
  );

  String? _currentDirectory;
  List<SpectrumMeta> _items = [];
  Map<String, SpectrumMeta> _itemsByPath = {};
  final Set<String> _selectedPaths = {};
  List<PlotCurve> _plotCurves = [];

  String _infoText =
      'Нажмите «Выбрать директорию», чтобы начать работу.';

  bool _processing = false;
  bool _loading = false;

  Future<void> _chooseDirectory() async {
    try {
      final directory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Выберите рабочую директорию',
      );

      if (directory == null || directory.isEmpty) {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _currentDirectory = directory;
        _selectedPaths.clear();
        _plotCurves = [];
      });

      _loader.invalidate();

      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }

      await _showError('Ошибка выбора директории', '$error');
    }
  }

  Future<void> _refresh() async {
    final directory = _currentDirectory;

    if (directory == null) {
      setState(() {
        _items = [];
        _itemsByPath = {};
        _plotCurves = [];
        _infoText = 'Директория не выбрана.';
      });

      return;
    }

    setState(() {
      _loading = true;
    });

    _loader.invalidate();

    try {
      final metas = await _scanner.scan(directory);

      if (!mounted) {
        return;
      }

      final byPath = {
        for (final meta in metas) meta.path: meta,
      };

      _selectedPaths.removeWhere((path) => !byPath.containsKey(path));

      final curves = await _loadSelectedCurves(metas, _selectedPaths);

      if (!mounted) {
        return;
      }

      setState(() {
        _items = metas;
        _itemsByPath = byPath;
        _plotCurves = curves;

        if (_items.isEmpty) {
          _infoText =
              'В выбранной директории не найдено подходящих файлов.';
        } else {
          _infoText = 'Кликните по названию файла, чтобы посмотреть информацию.\n'
              'Чекбокс добавляет файл на график.';
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _items = [];
        _itemsByPath = {};
        _plotCurves = [];
      });

      await _showError('Ошибка сканирования директории', '$error');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<List<PlotCurve>> _loadSelectedCurves(
    List<SpectrumMeta> items,
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

  Future<void> _updatePlot() async {
    final curves = await _loadSelectedCurves(_items, _selectedPaths);

    if (!mounted) {
      return;
    }

    setState(() {
      _plotCurves = curves;
    });
  }

  Future<void> _processSpectra() async {
    final directory = _currentDirectory;

    if (directory == null) {
      await _showWarning(
        'Обработка спектров',
        'Сначала выберите директорию.',
      );

      return;
    }

    if (_processing) {
      return;
    }

    setState(() {
      _processing = true;
    });

    _loader.invalidate();

    try {
      final report = await _processor.processDirectory(directory);

      if (!mounted) {
        return;
      }

      _loader.invalidate();

      await _refresh();

      if (!mounted) {
        return;
      }

      _showReport(report);
    } catch (error) {
      if (!mounted) {
        return;
      }

      await _showError('Ошибка обработки спектров', '$error');
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  void _showReport(ProcessingReport report) {
    final summary = [
      'Обработка завершена.',
      'Обработано файлов: ${report.processedFiles}',
      'Пропущено пустых шаблонов: ${report.skippedEmptyFiles}',
      'Создано средних файлов: ${report.createdAverageFiles.length}',
      'Создано файлов без фона: ${report.createdDifferenceFiles.length}',
    ];

    if (report.warnings.isNotEmpty) {
      summary.add('Предупреждений: ${report.warnings.length}');
    }

    final details = List<String>.from(summary);

    if (report.createdAverageFiles.isNotEmpty) {
      details.add('');
      details.add('Созданные средние файлы:');

      for (final path in report.createdAverageFiles) {
        details.add('  - ${p.basename(path)}');
      }
    }

    if (report.createdDifferenceFiles.isNotEmpty) {
      details.add('');
      details.add('Созданные файлы без фона:');

      for (final path in report.createdDifferenceFiles) {
        details.add('  - ${p.basename(path)}');
      }
    }

    if (report.warnings.isNotEmpty) {
      details.add('');
      details.add('Предупреждения:');

      for (final warning in report.warnings) {
        details.add('  ! $warning');
      }
    }

    setState(() {
      _infoText = details.join('\n');
    });

    _showAlertDialog(
      'Обработка спектров',
      summary.join('\n'),
    );
  }

  void _clearSelection() {
    _selectedPaths.clear();
    _updatePlot();

    setState(() {
      _infoText = 'Выбор снят.';
    });
  }

  Future<void> _toggle(String path, bool checked) async {
    if (checked) {
      _selectedPaths.add(path);
    } else {
      _selectedPaths.remove(path);
    }

    await _updatePlot();
    await _showInfo(path);
  }

  Future<void> _showInfo(String path) async {
    final meta = _itemsByPath[path];

    if (meta == null) {
      return;
    }

    try {
      final data = await _loader.load(path);

      if (!mounted) {
        return;
      }

      setState(() {
        _infoText = _buildInfoText(meta, data);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _infoText = _buildInfoText(meta, null, error: '$error');
      });
    }
  }

  String _buildInfoText(
    SpectrumMeta meta,
    SpectrumData? data, {
    String? error,
  }) {
    final lines = <String>[];

    lines.add('Файл: ${meta.filename}');
    lines.add('Тип: ${_kindName(meta.kind)}');

    if (meta.kind == SpectrumKind.difference) {
      if (meta.source != '?' && meta.source.isNotEmpty && meta.source != '—') {
        lines.add('Источник: ${meta.source}');
      } else {
        lines.add('Назначение: результат вычитания фона');
      }
    } else {
      lines.add('Источник/фон: ${meta.source}');
    }

    lines.add('Вещество: ${meta.substance.isEmpty ? '—' : meta.substance}');
    lines.add('Время из имени: ${meta.timeText.isEmpty ? '—' : meta.timeText}');

    if (meta.isBackground) {
      lines.add('Это фоновое измерение.');
    }

    if (error != null) {
      lines.add('Ошибка чтения: $error');
    } else if (data != null) {
      lines.add('Каналов: ${data.channelCount}');
      lines.add('Сумма отсчётов: ${data.total.toStringAsFixed(1)}');
      lines.add(
        'Максимум: ${data.maxCount.toStringAsFixed(1)} '
        '(канал ${data.maxChannel.toStringAsFixed(0)})',
      );
      lines.add(
        'Минимум: ${data.minCount.toStringAsFixed(1)} '
        '(канал ${data.minChannel.toStringAsFixed(0)})',
      );

      if (data.allZero) {
        lines.add(
          'Похоже, файл является пустым шаблоном: второй столбец полностью нулевой.',
        );
      }
    }

    return lines.join('\n');
  }

  String _kindName(SpectrumKind kind) {
    switch (kind) {
      case SpectrumKind.original:
        return 'Исходное измерение';
      case SpectrumKind.average:
        return 'Среднее значение (создано программой)';
      case SpectrumKind.difference:
        return 'Разность без фона (создано программой)';
      case SpectrumKind.unknown:
        return 'Неизвестный файл';
    }
  }

  Future<void> _showAlertDialog(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              child: SelectableText(message),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showError(String title, String message) {
    return _showAlertDialog(title, message);
  }

  Future<void> _showWarning(String title, String message) {
    return _showAlertDialog(title, message);
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _processing;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights, size: 20, color: AppTheme.primary),
            SizedBox(width: 10),
            Text('Просмотр и обработка спектров'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppToolbar(
              directory: _currentDirectory,
              busy: busy,
              onChooseDirectory: _chooseDirectory,
              onRefresh: _refresh,
              onProcess: _processSpectra,
              onClearSelection: _clearSelection,
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 400,
                    child: FileListPanel(
                      items: _items,
                      selectedPaths: _selectedPaths,
                      onToggle: _toggle,
                      onInfo: _showInfo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: PlotPanel(curves: _plotCurves),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 210,
                          child: InfoPanel(text: _infoText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}