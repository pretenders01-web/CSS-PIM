import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/app.dart';
import 'package:mobile/config/configuracao_api.dart';
import 'package:mobile/modelos/ingresso.dart';
import 'package:mobile/modelos/sessao.dart';
import 'package:mobile/modelos/usuario.dart';
import 'package:mobile/servicos/armazenamento_sessao.dart';
import 'package:mobile/servicos/autenticacao_servico.dart';
import 'package:mobile/servicos/cliente_api.dart';
import 'package:mobile/servicos/ingresso_servico.dart';

const enderecoDeTeste = 'http://api.test';

final configuracaoDeTeste = ConfiguracaoApi.interpretar(enderecoDeTeste, release: false);

/// Armazenamento em memória, no lugar do armazenamento seguro do aparelho.
class ArmazenamentoFalso implements ArmazenamentoSessao {
  ArmazenamentoFalso([this.guardada]);

  Sessao? guardada;

  @override
  Future<Sessao?> ler() async => guardada;

  @override
  Future<void> salvar(Sessao sessao) async => guardada = sessao;

  @override
  Future<void> limpar() async => guardada = null;
}

Usuario usuarioDeTeste({String perfil = 'CLIENTE'}) =>
    Usuario(id: 1, nome: 'Ana', email: 'ana@exemplo.com', perfil: perfil);

Sessao sessaoDeTeste({String perfil = 'CLIENTE', DateTime? expiraEm}) => Sessao(
  token: 'token-de-teste',
  expiraEm: expiraEm ?? DateTime.now().toUtc().add(const Duration(hours: 2)),
  usuario: usuarioDeTeste(perfil: perfil),
);

/// O JSON de um ingresso, como a Api devolve.
Map<String, dynamic> jsonDeIngresso({
  int ingressoId = 51,
  String timeA = 'Brasil',
  String timeB = 'Sérvia',
  String dataJogo = '2026-12-16T16:00:00',
  String estadioNome = 'AT&T Stadium',
  String estadioCidade = 'Dallas',
  String? numeroAssento = 'A01',
  bool utilizado = false,
}) => {
  'ingressoId': ingressoId,
  'vendaId': 7,
  'partida': '$timeA x $timeB',
  'timeA': timeA,
  'timeB': timeB,
  'dataJogo': dataJogo,
  'estadioNome': estadioNome,
  'estadioCidade': estadioCidade,
  'nomeSetor': 'Arquibancada Inferior',
  'numeroAssento': numeroAssento,
  'precoPago': 450.00,
  'codigoQR': 'codigo-$ingressoId',
  'dataExpiracao': dataJogo,
  'utilizado': utilizado,
};

Ingresso ingressoDeTeste({
  int ingressoId = 51,
  String dataJogo = '2026-12-16T16:00:00',
  bool utilizado = false,
}) => Ingresso.fromJson(
  jsonDeIngresso(ingressoId: ingressoId, dataJogo: dataJogo, utilizado: utilizado),
);

http.Response respostaJson(Object? corpo, [int codigo = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(corpo)),
  codigo,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Monta os serviços do app sobre um cliente HTTP falso.
ServicosDoApp servicosDeTeste(
  MockClientHandler responder, {
  ArmazenamentoFalso? armazenamento,
  Sessao? sessao,
}) {
  final api = ClienteApi(cliente: MockClient(responder), enderecoBase: enderecoDeTeste);
  final autenticacao = AutenticacaoServico(
    api: api,
    armazenamento: armazenamento ?? ArmazenamentoFalso(sessao),
  );
  return ServicosDoApp(autenticacao: autenticacao, ingressos: IngressoServico(api: api));
}
