import 'package:flutter/material.dart';

import 'composition/spectrum_workspace_dependencies.dart';
import 'controllers/spectrum_workspace_controller.dart';
import 'controllers/workspace_warning.dart';
import 'formatting/processing_report_formatter.dart';
import 'services/app_dialogs.dart';
import 'theme.dart';
import 'widgets/app_toolbar.dart';
import 'widgets/file_list_panel.dart';
import 'widgets/info_panel.dart';
import 'widgets/manual_actions_panel.dart';
import 'widgets/plot_panel.dart';

class SpectrumDesktopPage extends StatefulWidget {
  const SpectrumDesktopPage({super.key});

  @override
  State<SpectrumDesktopPage> createState() => _SpectrumDesktopPageState();
}

class _SpectrumDesktopPageState extends State<SpectrumDesktopPage> {
  late final SpectrumWorkspaceController _controller =
      SpectrumWorkspaceDependencies.create();

  final ProcessingReportFormatter _reportFormatter =
      ProcessingReportFormatter();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _chooseDirectory() async {
    try {
      await _controller.chooseDirectory();
    } on WorkspaceWarning catch (warning) {
      await _showWarning(warning);
    } catch (error) {
      await _showError('Ошибка выбора директории', error);
    }
  }

  Future<void> _refresh() async {
    try {
      await _controller.refresh();
    } on WorkspaceWarning catch (warning) {
      await _showWarning(warning);
    } catch (error) {
      await _showError('Ошибка сканирования директории', error);
    }
  }

  Future<void> _processSpectra() async {
    try {
      final report = await _controller.processSpectra();

      if (!mounted) {
        return;
      }

      await AppDialogs.report(context, report, _reportFormatter);
    } on WorkspaceWarning catch (warning) {
      await _showWarning(warning);
    } catch (error) {
      await _showError('Ошибка обработки спектров', error);
    }
  }

  Future<void> _runManualProcessing() async {
    try {
      final report = await _controller.runManualProcessing();

      if (!mounted) {
        return;
      }

      await AppDialogs.report(context, report, _reportFormatter);
    } on WorkspaceWarning catch (warning) {
      await _showWarning(warning);
    } catch (error) {
      await _showError('Ошибка ручной обработки', error);
    }
  }

  Future<void> _clearSelection() {
    return _controller.clearSelection();
  }

  Future<void> _showWarning(WorkspaceWarning warning) async {
    if (!mounted) {
      return;
    }

    await AppDialogs.warning(context, warning.title, warning.message);
  }

  Future<void> _showError(String title, Object error) async {
    if (!mounted) {
      return;
    }

    await AppDialogs.error(context, title, '$error');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final busy = _controller.busy;

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
                  directory: _controller.currentDirectory,
                  busy: busy,
                  onChooseDirectory: () {
                    _chooseDirectory();
                  },
                  onRefresh: () {
                    _refresh();
                  },
                  onProcess: () {
                    _processSpectra();
                  },
                  onClearSelection: () {
                    _clearSelection();
                  },
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: 380,
                              child: ManualActionsPanel(
                                operation: _controller.manualOperation,
                                onOperationChanged:
                                    _controller.setManualOperation,
                                items: _controller.items,
                                backgroundPath: _controller.backgroundPath,
                                onBackgroundChanged:
                                    _controller.setBackgroundPath,
                                selectedCount: _controller.selectedCount,
                                skipEmpty: _controller.skipEmpty,
                                onSkipEmptyChanged: _controller.setSkipEmpty,
                                clampNegative: _controller.clampNegative,
                                onClampNegativeChanged:
                                    _controller.setClampNegative,
                                canRun: _controller.canRunManual,
                                busy: busy,
                                onRun: () {
                                  _runManualProcessing();
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: FileListPanel(
                                items: _controller.items,
                                selectedPaths: _controller.selectedPaths,
                                onToggle: (path, checked) {
                                  _controller.toggle(path, checked);
                                },
                                onInfo: (path) {
                                  _controller.showInfo(path);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: PlotPanel(
                                curves: _controller.plotCurves,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 210,
                              child: InfoPanel(text: _controller.infoText),
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
      },
    );
  }
}