import '../modelos/ingresso.dart';
import 'cliente_api.dart';
import 'erros_api.dart';

/// Os ingressos do usuário logado.
class IngressoServico {
  IngressoServico({required this._api});

  final ClienteApi _api;

  Future<List<Ingresso>> listarMeusIngressos() async {
    final json = await _api.get('/api/vendas/meus-ingressos');
    try {
      return [
        for (final item in json as List<dynamic>) Ingresso.fromJson(item as Map<String, dynamic>),
      ];
    } on TypeError {
      throw const ApiException(ClienteApi.respostaInesperada);
    } on FormatException {
      throw const ApiException(ClienteApi.respostaInesperada);
    }
  }
}
