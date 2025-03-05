import 'package:file_picker/file_picker.dart';

Future<FilePickerResult?> pickPdfFile() async {
  return await FilePicker.platform
      .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
}
