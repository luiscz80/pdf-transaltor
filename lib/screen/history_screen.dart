import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<String>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _getHistory();
  }

  Future<List<String>> _getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('pdfHistory') ?? [];
    return history.reversed.toList();
  }

  Future<void> _removeFromHistory(String pdfPath) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('pdfHistory') ?? [];
    history.remove(pdfPath);
    await prefs.setStringList('pdfHistory', history);
  }

  Future<void> _removeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('savedPdfPath');
    prefs.remove('currentPage');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Historial de PDF',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: FutureBuilder<List<String>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error cargando el historial.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay historial disponible.'));
          } else {
            return ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                String pdfPath = snapshot.data![index];

                return Card(
                  elevation: 5,
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Theme.of(context).primaryColor,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10),
                    leading: Icon(
                      Icons.history,
                      color: Colors.blueAccent,
                      size: 30,
                    ),
                    title: Text(
                      pdfPath,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await _removeFromHistory(pdfPath);
                            await _removeFromPrefs();

                            setState(() {
                              _historyFuture = _getHistory();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
