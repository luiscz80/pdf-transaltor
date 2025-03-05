import 'package:shared_preferences/shared_preferences.dart';

Future<void> addToHistory(String fileName) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> history = prefs.getStringList('pdfHistory') ?? [];
  if (!history.contains(fileName)) {
    history.add(fileName);
    await prefs.setStringList('pdfHistory', history);
  }
}

Future<void> savePdfToPrefs(String path, int page) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('savedPdfPath', path);
  await prefs.setInt('currentPage', page);
}

Future<void> savePageToPrefs(int page) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setInt('currentPage', page);
}
