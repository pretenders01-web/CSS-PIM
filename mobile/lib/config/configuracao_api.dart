import 'package:flutter/foundation.dart';

/// O endereço da Api vem de fora do código, na hora de rodar o app:
///   `flutter run --dart-define=API_URL=<endereço da Api>`
/// A seção 8 de docs/Passo_a_passo_Mobile_PIM_IV.md traz o endereço de cada aparelho.
///
/// Em build de release, só https é aceito. O manifesto do Android não basta para isso:
/// a política de HTTP do Android vale para conexões nativas, e as conexões do Dart não passam
/// por ela (testado no emulador). A barreira real é esta classe.
class ConfiguracaoApi {
  const ConfiguracaoApi._({this.enderecoBase, this.erro});

  /// Endereço sem a barra final. É nulo quando a configuração tem erro.
  final String? enderecoBase;

  /// O que está errado, para mostrar na tela. É nulo quando está tudo certo.
  final String? erro;

  bool get valida => erro == null;

  factory ConfiguracaoApi.doAmbiente() =>
      ConfiguracaoApi.interpretar(const String.fromEnvironment('API_URL'));

  /// [release] é um parâmetro para os testes poderem conferir os dois modos.
  factory ConfiguracaoApi.interpretar(String valor, {bool release = kReleaseMode}) {
    final endereco = valor.trim();

    if (endereco.isEmpty) {
      return const ConfiguracaoApi._(
        erro:
            'O endereço da Api não foi informado.\n\n'
            'Rode o app com:\nflutter run --dart-define=API_URL=<endereço da Api>',
      );
    }

    final uri = Uri.tryParse(endereco);
    final temEsquemaValido = uri != null && uri.hasAuthority && (uri.isScheme('http') || uri.isScheme('https'));
    if (!temEsquemaValido) {
      return const ConfiguracaoApi._(
        erro: 'O endereço da Api é inválido. Ele precisa começar com http:// ou https://.',
      );
    }

    if (release && !uri.isScheme('https')) {
      return const ConfiguracaoApi._(
        erro: 'Por segurança, a versão final do app só aceita um endereço da Api com https://.',
      );
    }

    return ConfiguracaoApi._(enderecoBase: endereco.replaceFirst(RegExp(r'/+$'), ''));
  }
}
