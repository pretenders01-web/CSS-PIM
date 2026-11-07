import '../modelos/ingresso.dart';
import '../modelos/ingresso_validado.dart';
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

  /// A situação atual de um ingresso, para a consulta periódica da tela do QR.
  /// A Api não tem rota de um único ingresso, então lê a lista e procura. Trocar por uma rota
  /// própria, se ela existir um dia, afeta só este método.
  Future<Ingresso?> consultar(int ingressoId) async {
    final lista = await listarMeusIngressos();
    for (final ingresso in lista) {
      if (ingresso.ingressoId == ingressoId) return ingresso;
    }
    return null;
  }

  /// Portaria: valida o código e marca o ingresso como utilizado.
  /// Uma recusa chega como ApiException com o código 400 e o motivo na mensagem.
  Future<IngressoValidado> validar(String codigoQR) async {
    final json = await _api.post('/api/vendas/validar', {'codigoQR': codigoQR});
    try {
      return IngressoValidado.fromJson(json as Map<String, dynamic>);
    } on TypeError {
      throw const ApiException(ClienteApi.respostaInesperada);
    } on FormatException {
      throw const ApiException(ClienteApi.respostaInesperada);
    }
  }
}
