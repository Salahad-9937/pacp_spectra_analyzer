import 'dart:io';

import '../../domain/models.dart';
import '../io/spectrum_file_scanner.dart';
import 'average_groups_step.dart';
import 'experiment_matcher.dart';
import 'spectrum_grouper.dart';
import 'subtract_background_step.dart';

class SpectrumProcessor {
  SpectrumProcessor({
    required this.scanner,
    required this.grouper,
    required this.averageStep,
    required this.experimentMatcher,
    required this.subtractStep,
  });

  final SpectrumFileScanner scanner;
  final SpectrumGrouper grouper;
  final AverageGroupsStep averageStep;
  final ExperimentMatcher experimentMatcher;
  final SubtractBackgroundStep subtractStep;

  Future<ProcessingReport> processDirectory(String directory) async {
    final report = ProcessingReport();

    if (directory.isEmpty) {
      report.warnings.add('Директория для обработки не найдена.');
      return report;
    }

    final dir = Directory(directory);

    if (!await dir.exists()) {
      report.warnings.add('Директория для обработки не найдена.');
      return report;
    }

    final metas = await scanner.scan(directory);
    final groups = grouper.groupOriginals(metas);

    final averages = await averageStep.execute(
      directory: directory,
      groups: groups,
      report: report,
    );

    final matchResult = experimentMatcher.match(averages);
    report.warnings.addAll(matchResult.warnings);

    await subtractStep.execute(
      directory: directory,
      experiments: matchResult.experiments,
      report: report,
    );

    return report;
  }
}