import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modelos/sessao.dart';
import 'erros_api.dart';

/// A única classe do app que faz HTTP. Telas e outros serviços passam por aqui.
///
/// Sem importar dart:io, para o app funcionar também no navegador: no Android, uma falha de
/// conexão do pacote http já chega como http.ClientException.
class ClienteApi {
  ClienteApi({
    required this._cliente,
    required this._enderecoBase,
    this.tempoLimite = const Duration(seconds: 10),
    DateTime Function()? relogio,
  }) : _relogio = relogio ?? DateTime.now;

  final http.Client _cliente;
  final String _enderecoBase;
  final DateTime Function() _relogio;
  final Duration tempoLimite;

  /// A sessão atual, que envia o token. O AutenticacaoServico preenche os dois campos abaixo.
  Sessao? Function() lerSessao = _semSessao;

  /// Chamado quando o token vence ou é recusado.
  void Function() aoExpirarSessao = _nadaAFazer;

  static Sessao? _semSessao() => null;
  static void _nadaAFazer() {}

  Future<dynamic> get(String rota) => _enviar(
    (uri, cabecalhos) => _cliente.get(uri, headers: cabecalhos),
    rota,
    autenticado: true,
  );

  /// [autenticado] é falso só no login, onde o 401 quer dizer "senha errada", e não "sessão vencida".
  Future<dynamic> post(String rota, Map<String, dynamic> corpo, {bool autenticado = true}) => _enviar(
    (uri, cabecalhos) => _cliente.post(uri, headers: cabecalhos, body: jsonEncode(corpo)),
    rota,
    autenticado: autenticado,
  );

  Future<dynamic> _enviar(
    Future<http.Response> Function(Uri uri, Map<String, String> cabecalhos) requisicao,
    String rota, {
    required bool autenticado,
  }) async {
    final cabecalhos = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (autenticado) {
      final sessao = lerSessao();
      // Token vencido nem sai do aparelho.
      if (sessao == null || sessao.expirada(_relogio().toUtc())) {
        aoExpirarSessao();
        throw const SessaoExpiradaException();
      }
      cabecalhos['Authorization'] = 'Bearer ${sessao.token}';
    }

    final http.Response resposta;
    try {
      resposta = await requisicao(Uri.parse('$_enderecoBase$rota'), cabecalhos).timeout(tempoLimite);
    } on TimeoutException {
      throw const SemConexaoException();
    } on http.ClientException {
      throw const SemConexaoException();
    }

    // Lê os bytes como UTF-8 para os acentos não dependerem do cabeçalho da resposta.
    final texto = utf8.decode(resposta.bodyBytes, allowMalformed: true);

    if (resposta.statusCode == 401 && autenticado) {
      aoExpirarSessao();
      throw const SessaoExpiradaException();
    }

    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw ApiException(mensagemDoErro(texto, resposta.statusCode), codigo: resposta.statusCode);
    }

    if (texto.isEmpty) return null;
    try {
      return jsonDecode(texto);
    } on FormatException {
      throw const ApiException(respostaInesperada);
    }
  }

  static const String respostaInesperada = 'O servidor enviou uma resposta inesperada. Tente de novo.';
}
