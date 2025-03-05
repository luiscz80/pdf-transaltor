import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/file_picker_helper.dart';
import '../helper/pdf_history_helper.dart';
import '../helper/pdf_translation_helper.dart';

class PdfTranslatorScreen extends StatefulWidget {
  @override
  _PdfTranslatorScreenState createState() => _PdfTranslatorScreenState();
}

class _PdfTranslatorScreenState extends State<PdfTranslatorScreen> {
  PdfDocument? _document;
  late PdfViewerController _pdfViewerController;
  int _currentPage = 1;
  bool _isLoading = false;
  int _totalPages = 0;
  Future<Uint8List>? _pdfBytesFuture;
  String? _pdfFilePath;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _isLoading = true;
    _loadPdfFromPrefs();
  }

  Future<void> _loadPdfFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPdfPath = prefs.getString('savedPdfPath');
    final savedPage = prefs.getInt('currentPage') ?? 1;

    if (savedPdfPath != null) {
      final file = File(savedPdfPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final document = PdfDocument(inputBytes: Uint8List.fromList(bytes));

        setState(() {
          _document = document;
          _totalPages = document.pages.count;
          _pdfBytesFuture = Future.value(Uint8List.fromList(bytes));
          _currentPage = savedPage;
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pdfViewerController.jumpToPage(_currentPage);
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickPdf() async {
    setState(() {
      _isLoading = true;
    });

    final result = await pickPdfFile();
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final bytes = await File(path).readAsBytes();
      final uint8ListBytes = Uint8List.fromList(bytes);

      try {
        final document = PdfDocument(inputBytes: uint8ListBytes);
        setState(() {
          _document = document;
          _totalPages = document.pages.count;
          _pdfBytesFuture = Future.value(uint8ListBytes);
          _isLoading = false;
          _currentPage = 1;
          _pdfFilePath = path;
        });

        final fileName = result.files.single.name;
        addToHistory(fileName);
        savePdfToPrefs(path, _currentPage);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar el PDF: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _extractTextFromPage(int pageNumber) {
    if (_document == null ||
        pageNumber > _document!.pages.count ||
        pageNumber < 1) {
      return '';
    }
    final text = PdfTextExtractor(_document!).extractText(
        startPageIndex: pageNumber - 1, endPageIndex: pageNumber - 1);
    return text.isEmpty ? 'No hay texto extraído' : text;
  }

  Future<void> _translateWithGoogle(String text) async {
    await translateWithGoogle(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Traductor de PDF', style: TextStyle(fontSize: 12)),
            if (_document != null)
              Text(
                'Página $_currentPage de $_totalPages',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
          ),
          IconButton(
            icon: Icon(Icons.file_open_outlined, color: Colors.white),
            onPressed: _pickPdf,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _document == null
              ? Center(child: _buildNoPdfWidget())
              : Column(
                  children: [
                    Expanded(flex: 2, child: buildPdfViewer()),
                    Expanded(flex: 1, child: buildTextExtractor()),
                  ],
                ),
    );
  }

  Widget _buildNoPdfWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.picture_as_pdf, size: 60, color: Colors.indigo),
        SizedBox(height: 20),
        Text(
          'Selecciona un archivo PDF',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
        ),
        SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _pickPdf,
          icon: Icon(Icons.file_open, color: Colors.white),
          label: Text('Elegir PDF', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget buildPdfViewer() {
    return FutureBuilder<Uint8List>(
      future: _pdfBytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
              child: Text('Error al cargar el PDF.',
                  style: TextStyle(color: Colors.white)));
        } else if (snapshot.hasData) {
          return Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 63, 63, 63),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SfPdfViewer.memory(
              snapshot.data!,
              controller: _pdfViewerController,
              onPageChanged: (PdfPageChangedDetails details) {
                setState(() {
                  _currentPage = details.newPageNumber;
                  savePageToPrefs(_currentPage);
                  if (_pdfFilePath != null) {
                    savePdfToPrefs(_pdfFilePath!, _currentPage);
                  }
                });
              },
            ),
          );
        } else {
          return Center(
              child: Text('No se encontraron datos.',
                  style: TextStyle(color: Colors.white)));
        }
      },
    );
  }

  Widget buildTextExtractor() {
    return Padding(
      padding: EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Texto extraído de la página $_currentPage:',
                style: TextStyle(
                  color: Color.fromARGB(255, 63, 63, 63),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final text = _extractTextFromPage(_currentPage);
                  _translateWithGoogle(text);
                },
                icon: Icon(Icons.translate, color: Colors.white),
                label: Text('Traducir', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 47, 111, 221),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 63, 63, 63),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(4),
                child: Text(
                  _extractTextFromPage(_currentPage),
                  style: TextStyle(
                      color: const Color.fromARGB(255, 219, 218, 218),
                      fontSize: 12),
                ),
              ),
            ),
          ),
          SizedBox(height: 0),
        ],
      ),
    );
  }
}
