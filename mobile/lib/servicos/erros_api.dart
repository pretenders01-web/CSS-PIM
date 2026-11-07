import 'dart:convert';

/// A Api respondeu com um erro. A mensagem já pode ser mostrada na tela.
class ApiException implements Exception {
  const ApiException(this.mensagem, {this.codigo});

  final String mensagem;

  /// O código HTTP. É nulo quando a resposta veio em um formato inesperado.
  final int? codigo;

  @override
  String toString() => 'ApiException($codigo): $mensagem';
}

/// O token venceu ou foi recusado. O app volta ao login.
class SessaoExpiradaException implements Exception {
  const SessaoExpiradaException();
}

/// A resposta nem chegou: sem rede, servidor fora do ar ou tempo esgotado.
class SemConexaoException implements Exception {
  const SemConexaoException();

  static const String mensagem = 'Não foi possível falar com o servidor. Confira a conexão e tente de novo.';
}

/// Tira do corpo da resposta a mensagem para o usuário. A Api tem dois formatos de erro:
///   - regra de negócio e login: { "erro": "..." };
///   - campo inválido no DTO: { "errors": { "Email": ["E-mail inválido."] } }.
/// 401 e 403 de autorização vêm com o corpo vazio, e um erro inesperado pode nem ser JSON.
/// Nesses casos, entra um texto padrão, sem detalhe técnico.
String mensagemDoErro(String corpo, int codigo) {
  try {
    final json = jsonDecode(corpo);
    if (json is Map<String, dynamic>) {
      final erro = json['erro'];
      if (erro is String && erro.isNotEmpty) return erro;

      final erros = json['errors'];
      if (erros is Map<String, dynamic>) {
        for (final mensagens in erros.values) {
          if (mensagens is List && mensagens.isNotEmpty && mensagens.first is String) {
            return mensagens.first as String;
          }
        }
      }
    }
  } on FormatException {
    // Corpo vazio ou que não é JSON: vale o texto padrão abaixo.
  }

  return switch (codigo) {
    403 => 'Sua conta não tem permissão para isso. Se o seu perfil mudou, entre de novo.',
    >= 500 => 'O servidor teve um problema. Tente de novo em instantes.',
    _ => 'Não foi possível concluir a operação. Tente de novo.',
  };
}
