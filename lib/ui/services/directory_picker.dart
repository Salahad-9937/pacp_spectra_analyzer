import 'package:file_picker/file_picker.dart';

abstract class DirectoryPicker {
  Future<String?> pickDirectory({String? dialogTitle});
}

class FilePickerDirectoryPicker implements DirectoryPicker {
  const FilePickerDirectoryPicker();

  @override
  Future<String?> pickDirectory({String? dialogTitle}) {
    return FilePicker.platform.getDirectoryPath(
      dialogTitle: dialogTitle ?? 'Выберите директорию',
    );
  }
}