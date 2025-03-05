import 'package:flutter/material.dart';
import 'package:pdf_translator/screen/history_screen.dart';
import 'package:pdf_translator/screen/pdf_translator_screen.dart';

void main() {
  runApp(PdfTranslatorApp());
}

class PdfTranslatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 63, 63, 63),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color.fromARGB(255, 63, 63, 63),
          titleTextStyle: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
            bodyMedium: TextStyle(fontSize: 16, color: Colors.black),
            titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      home: PdfTranslatorScreen(),
      routes: {
        '/history': (context) => HistoryScreen(),
      },
    );
  }
}
