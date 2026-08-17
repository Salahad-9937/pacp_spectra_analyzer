class ProcessingReport {
  int processedFiles = 0;
  int skippedEmptyFiles = 0;

  final List<String> createdAverageFiles = [];
  final List<String> createdSumFiles = [];
  final List<String> createdDifferenceFiles = [];
  final List<String> warnings = [];

  void addWarning(String warning) {
    warnings.add(warning);
  }
}