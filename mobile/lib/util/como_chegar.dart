import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// O endereço de busca do Google Maps, sem chave de API.
/// Montado pelo Uri, e não concatenando texto: "AT&T Stadium" está no seed, e o & quebraria o endereço.
Uri enderecoDoMapa(String estadio, String cidade) => Uri.https('www.google.com', '/maps/search/', {
  'api': '1',
  'query': '$estadio, $cidade',
});

/// Abre o endereço fora do app. Devolve false se não houver como abrir.
Future<bool> abrirLinkExterno(Uri endereco) async {
  try {
    return await launchUrl(endereco, mode: LaunchMode.externalApplication);
  } on PlatformException {
    return false;
  }
}
