import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../modelos/sessao.dart';

/// Onde a sessão fica guardada entre uma abertura do app e outra.
/// É uma interface para os testes poderem usar uma versão em memória.
abstract interface class ArmazenamentoSessao {
  Future<Sessao?> ler();
  Future<void> salvar(Sessao sessao);
  Future<void> limpar();
}

/// A versão real, no armazenamento seguro do aparelho, que cifra os dados.
class ArmazenamentoSeguro implements ArmazenamentoSessao {
  ArmazenamentoSeguro([FlutterSecureStorage? armazenamento])
    : _armazenamento = armazenamento ?? const FlutterSecureStorage();

  static const String _chave = 'sessao';

  final FlutterSecureStorage _armazenamento;

  @override
  Future<Sessao?> ler() async {
    try {
      final texto = await _armazenamento.read(key: _chave);
      if (texto == null) return null;
      return Sessao.fromJson(jsonDecode(texto) as Map<String, dynamic>);
    } on FormatException {
      await limpar();
    } on TypeError {
      await limpar();
    } on PlatformException {
      // A chave do aparelho mudou (por exemplo, ao restaurar um backup): basta entrar de novo.
      await limpar();
    }
    return null;
  }

  @override
  Future<void> salvar(Sessao sessao) =>
      _armazenamento.write(key: _chave, value: jsonEncode(sessao.toJson()));

  @override
  Future<void> limpar() async {
    try {
      await _armazenamento.delete(key: _chave);
    } on PlatformException {
      // Sem como apagar, a sessão continua fora de uso na memória: nada mais a fazer aqui.
    }
  }
}
