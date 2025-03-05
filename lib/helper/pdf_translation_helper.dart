import 'package:url_launcher/url_launcher.dart';

Future<void> translateWithGoogle(String text) async {
  final url =
      'https://translate.google.com/?sl=en&tl=es&text=${Uri.encodeComponent(text)}';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'No se pudo abrir Google Translate';
  }
}
