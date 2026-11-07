import 'dart:async';

import 'package:flutter/foundation.dart';

import '../modelos/sessao.dart';
import 'armazenamento_sessao.dart';
import 'cliente_api.dart';
import 'erros_api.dart';

/// Login, saída e sessão guardada.
/// O [sessao] é o único estado global do app: o app.dart escuta e troca entre login e tela inicial.
class AutenticacaoServico {
  AutenticacaoServico({
    required this._api,
    required this._armazenamento,
    DateTime Function()? relogio,
  }) : _relogio = relogio ?? DateTime.now {
    _api.lerSessao = () => sessao.value;
    _api.aoExpirarSessao = _expirar;
  }

  final ClienteApi _api;
  final ArmazenamentoSessao _armazenamento;
  final DateTime Function() _relogio;

  final ValueNotifier<Sessao?> sessao = ValueNotifier<Sessao?>(null);

  /// Mensagem que a tela de login mostra quando o usuário foi levado de volta para ela.
  String? avisoDoLogin;

  /// Lança ApiException (senha errada, conta desativada) ou SemConexaoException.
  Future<void> entrar(String email, String senha) async {
    final json = await _api.post(
      '/api/auth/login',
      {'email': email, 'senha': senha},
      autenticado: false,
    );

    final Sessao nova;
    try {
      nova = Sessao.fromJson(json as Map<String, dynamic>);
    } on TypeError {
      throw const ApiException(ClienteApi.respostaInesperada);
    } on FormatException {
      throw const ApiException(ClienteApi.respostaInesperada);
    }

    await _armazenamento.salvar(nova);
    avisoDoLogin = null;
    sessao.value = nova;
  }

  Future<void> sair() async {
    avisoDoLogin = null;
    sessao.value = null;
    await _armazenamento.limpar();
  }

  /// Ao abrir o app: recupera a sessão guardada, se ela ainda valer.
  Future<void> restaurar() async {
    final guardada = await _armazenamento.ler();
    if (guardada == null) return;

    if (guardada.expirada(_relogio().toUtc())) {
      await _armazenamento.limpar();
      return;
    }

    sessao.value = guardada;
  }

  /// Confere se a conta continua ativa: a Api devolve 401 se ela foi desativada, e o ClienteApi
  /// cuida da saída. Roda sem travar a abertura do app. Sem rede, a sessão continua.
  /// O perfil não é trocado pelo que vier aqui: o que a Api confere é o perfil dentro do token.
  Future<void> confirmarConta() async {
    if (sessao.value == null) return;
    try {
      await _api.get('/api/usuarios/me');
    } on SessaoExpiradaException {
      // O _expirar já levou de volta ao login.
    } on SemConexaoException {
      // Sem rede: vale a sessão guardada.
    } on ApiException {
      // Erro do servidor não é motivo para derrubar a sessão.
    }
  }

  void _expirar() {
    if (sessao.value == null) return;
    avisoDoLogin = 'Sua sessão expirou. Entre de novo.';
    sessao.value = null;
    unawaited(_armazenamento.limpar());
  }
}
