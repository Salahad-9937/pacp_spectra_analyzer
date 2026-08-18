class WorkspaceWarning implements Exception {
  const WorkspaceWarning(this.title, this.message);

  final String title;
  final String message;

  @override
  String toString() => message;
}