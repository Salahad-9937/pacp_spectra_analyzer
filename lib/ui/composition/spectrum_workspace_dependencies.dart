import '../../services/io/spectrum_file_scanner.dart';
import '../../services/io/spectrum_file_writer.dart';
import '../../services/loading/cached_spectrum_loader.dart';
import '../../services/loading/spectrum_file_reader.dart';
import '../../services/loading/spectrum_text_parser.dart';
import '../../services/parsing/file_name_parser.dart';
import '../../services/parsing/spectrum_file_candidate.dart';
import '../../services/processing/average_groups_step.dart';
import '../../services/processing/background_subtractor.dart';
import '../../services/processing/experiment_matcher.dart';
import '../../services/processing/generated_file_namer.dart';
import '../../services/processing/manual_spectrum_processor.dart';
import '../../services/processing/spectrum_averager.dart';
import '../../services/processing/spectrum_grouper.dart';
import '../../services/processing/spectrum_processor.dart';
import '../../services/processing/spectrum_summator.dart';
import '../../services/processing/subtract_background_step.dart';
import '../controllers/spectrum_workspace_controller.dart';
import '../formatting/processing_report_formatter.dart';
import '../formatting/spectrum_info_formatter.dart';
import '../loading/plot_curve_loader.dart';
import '../services/directory_picker.dart';

class SpectrumWorkspaceDependencies {
  const SpectrumWorkspaceDependencies._();

  static SpectrumWorkspaceController create() {
    final fileNameParser = FileNameParser(
      candidate: SpectrumFileCandidate(),
    );

    final scanner = SpectrumFileScanner(fileNameParser);

    final fileReader = SpectrumFileReader(
      textParser: SpectrumTextParser(),
    );

    final cachedLoader = CachedSpectrumLoader(fileReader);

    final writer = SpectrumFileWriter(
      formatter: SpectrumDataFormatter(),
    );

    final fileNamer = GeneratedFileNamer();

    final averager = SpectrumAverager();
    final summator = SpectrumSummator();
    final subtractor = BackgroundSubtractor();

    final processor = SpectrumProcessor(
      scanner: scanner,
      grouper: SpectrumGrouper(),
      averageStep: AverageGroupsStep(
        loader: fileReader,
        averager: averager,
        writer: writer,
        fileNamer: fileNamer,
      ),
      experimentMatcher: ExperimentMatcher(),
      subtractStep: SubtractBackgroundStep(
        subtractor: subtractor,
        writer: writer,
        fileNamer: fileNamer,
      ),
    );

    final manualProcessor = ManualSpectrumProcessor(
      loader: cachedLoader,
      writer: writer,
      averager: averager,
      summator: summator,
      subtractor: subtractor,
      fileNamer: fileNamer,
    );

    return SpectrumWorkspaceController(
      directoryPicker: const FilePickerDirectoryPicker(),
      scanner: scanner,
      loader: cachedLoader,
      processor: processor,
      manualProcessor: manualProcessor,
      curveLoader: PlotCurveLoader(cachedLoader),
      infoFormatter: SpectrumInfoFormatter(),
      reportFormatter: ProcessingReportFormatter(),
    );
  }
}