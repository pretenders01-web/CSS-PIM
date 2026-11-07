import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/servicos/autenticacao_servico.dart';
import 'package:mobile/servicos/cliente_api.dart';
import 'package:mobile/servicos/erros_api.dart';

import '../apoio/falsos.dart';

Map<String, dynamic> jsonDoLogin() => {
  'token': 'token-novo',
  'expiraEm': DateTime.now().toUtc().add(const Duration(hours: 2)).toIso8601String(),
  'usuario': usuarioDeTeste().toJson(),
};

({AutenticacaoServico autenticacao, ClienteApi api, ArmazenamentoFalso armazenamento, List<http.Request> pedidos})
montar(
  Future<http.Response> Function(http.Request) responder, {
  ArmazenamentoFalso? armazenamento,
  Duration tempoLimite = const Duration(seconds: 10),
}) {
  final pedidos = <http.Request>[];
  final guarda = armazenamento ?? ArmazenamentoFalso();
  final api = ClienteApi(
    cliente: MockClient((pedido) {
      pedidos.add(pedido);
      return responder(pedido);
    }),
    enderecoBase: enderecoDeTeste,
    tempoLimite: tempoLimite,
  );
  return (
    autenticacao: AutenticacaoServico(api: api, armazenamento: guarda),
    api: api,
    armazenamento: guarda,
    pedidos: pedidos,
  );
}

void main() {
  group('entrar', () {
    test('login certo guarda a sessão e envia o que a Api espera', () async {
      final m = montar((_) async => respostaJson(jsonDoLogin()));

      await m.autenticacao.entrar('ana@exemplo.com', 'segredo');

      expect(m.autenticacao.sessao.value?.token, 'token-novo');
      expect(m.armazenamento.guardada?.token, 'token-novo');
      expect(m.pedidos.single.url.toString(), '$enderecoDeTeste/api/auth/login');
      expect(m.pedidos.single.body, contains('"senha":"segredo"'));
      expect(m.pedidos.single.headers.containsKey('Authorization'), isFalse);
    });

    test('a senha não é guardada', () async {
      final m = montar((_) async => respostaJson(jsonDoLogin()));

      await m.autenticacao.entrar('ana@exemplo.com', 'segredo');

      expect(m.armazenamento.guardada!.toJson().toString(), isNot(contains('segredo')));
    });

    test('401 do login é mensagem no formulário, não sessão vencida', () async {
      final m = montar((_) async => respostaJson({'erro': 'E-mail ou senha incorretos.'}, 401));

      await expectLater(
        m.autenticacao.entrar('ana@exemplo.com', 'errada'),
        throwsA(isA<ApiException>().having((e) => e.mensagem, 'mensagem', 'E-mail ou senha incorretos.')),
      );
      expect(m.autenticacao.avisoDoLogin, isNull);
    });

    test('400 com errors usa a primeira mensagem', () async {
      final m = montar(
        (_) async => respostaJson({
          'errors': {
            'Email': ['E-mail inválido.'],
          },
        }, 400),
      );

      await expectLater(
        m.autenticacao.entrar('x', 'y'),
        throwsA(isA<ApiException>().having((e) => e.mensagem, 'mensagem', 'E-mail inválido.')),
      );
    });

    test('falha de conexão vira SemConexaoException', () async {
      final m = montar((_) async => throw http.ClientException('sem rede'));

      await expectLater(m.autenticacao.entrar('a@b', 'c'), throwsA(isA<SemConexaoException>()));
    });

    test('tempo esgotado vira SemConexaoException', () async {
      final m = montar(
        (_) => Completer<http.Response>().future,
        tempoLimite: const Duration(milliseconds: 10),
      );

      await expectLater(m.autenticacao.entrar('a@b', 'c'), throwsA(isA<SemConexaoException>()));
    });

    test('500 com HTML vira mensagem amigável', () async {
      final m = montar((_) async => http.Response('<html>erro</html>', 500));

      await expectLater(
        m.autenticacao.entrar('a@b', 'c'),
        throwsA(isA<ApiException>().having((e) => e.mensagem, 'mensagem', contains('servidor'))),
      );
    });

    test('resposta 200 fora do formato não derruba o app', () async {
      final m = montar((_) async => respostaJson({'token': 1}));

      await expectLater(m.autenticacao.entrar('a@b', 'c'), throwsA(isA<ApiException>()));
    });
  });

  group('chamadas autenticadas', () {
    test('enviam o cabeçalho Authorization', () async {
      final m = montar((_) async => respostaJson(<Object>[]), armazenamento: ArmazenamentoFalso(sessaoDeTeste()));
      await m.autenticacao.restaurar();

      await m.api.get('/api/vendas/meus-ingressos');

      expect(m.pedidos.single.headers['Authorization'], 'Bearer token-de-teste');
    });

    test('401 derruba a sessão, limpa o armazenamento e avisa no login', () async {
      final m = montar((_) async => http.Response('', 401), armazenamento: ArmazenamentoFalso(sessaoDeTeste()));
      await m.autenticacao.restaurar();

      await expectLater(m.api.get('/api/vendas/meus-ingressos'), throwsA(isA<SessaoExpiradaException>()));

      expect(m.autenticacao.sessao.value, isNull);
      expect(m.armazenamento.guardada, isNull);
      expect(m.autenticacao.avisoDoLogin, contains('expirou'));
    });

    test('token vencido nem sai do aparelho', () async {
      final m = montar((_) async => respostaJson(<Object>[]), armazenamento: ArmazenamentoFalso(sessaoDeTeste()));
      await m.autenticacao.restaurar();
      m.autenticacao.sessao.value = sessaoDeTeste(
        expiraEm: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );

      await expectLater(m.api.get('/api/vendas/meus-ingressos'), throwsA(isA<SessaoExpiradaException>()));

      expect(m.pedidos, isEmpty);
      expect(m.autenticacao.sessao.value, isNull);
    });

    test('403 é erro comum e não derruba a sessão', () async {
      final m = montar((_) async => http.Response('', 403), armazenamento: ArmazenamentoFalso(sessaoDeTeste()));
      await m.autenticacao.restaurar();

      await expectLater(
        m.api.post('/api/vendas/validar', {'codigoQR': 'x'}),
        throwsA(isA<ApiException>().having((e) => e.codigo, 'codigo', 403)),
      );
      expect(m.autenticacao.sessao.value, isNotNull);
    });

    test('os acentos chegam certos', () async {
      final m = montar(
        (_) async => respostaJson([jsonDeIngresso()]),
        armazenamento: ArmazenamentoFalso(sessaoDeTeste()),
      );
      await m.autenticacao.restaurar();

      final lista = await m.api.get('/api/vendas/meus-ingressos') as List<dynamic>;

      expect((lista.first as Map<String, dynamic>)['timeB'], 'Sérvia');
    });
  });

  group('restaurar e confirmarConta', () {
    test('sem nada guardado, fica sem sessão', () async {
      final m = montar((_) async => respostaJson({}));

      await m.autenticacao.restaurar();

      expect(m.autenticacao.sessao.value, isNull);
      expect(m.pedidos, isEmpty);
    });

    test('sessão vencida é apagada e não vai à Api', () async {
      final vencida = sessaoDeTeste(expiraEm: DateTime.now().toUtc().subtract(const Duration(minutes: 1)));
      final m = montar((_) async => respostaJson({}), armazenamento: ArmazenamentoFalso(vencida));

      await m.autenticacao.restaurar();

      expect(m.autenticacao.sessao.value, isNull);
      expect(m.armazenamento.guardada, isNull);
      expect(m.pedidos, isEmpty);
    });

    test('conta desativada cai no login', () async {
      final m = montar((_) async => http.Response('', 401), armazenamento: ArmazenamentoFalso(sessaoDeTeste()));
      await m.autenticacao.restaurar();
      expect(m.autenticacao.sessao.value, isNotNull);

      await m.autenticacao.confirmarConta();

      expect(m.pedidos.single.url.path, '/api/usuarios/me');
      expect(m.autenticacao.sessao.value, isNull);
    });

    test('sem rede, a sessão continua', () async {
      final m = montar(
        (_) async => throw http.ClientException('sem rede'),
        armazenamento: ArmazenamentoFalso(sessaoDeTeste()),
      );
      await m.autenticacao.restaurar();

      await m.autenticacao.confirmarConta();

      expect(m.autenticacao.sessao.value, isNotNull);
    });

    test('o perfil continua o do login, mesmo que /me diga outro', () async {
      final m = montar(
        (_) async => respostaJson(usuarioDeTeste(perfil: 'ADMIN').toJson()),
        armazenamento: ArmazenamentoFalso(sessaoDeTeste()),
      );
      await m.autenticacao.restaurar();

      await m.autenticacao.confirmarConta();

      expect(m.autenticacao.sessao.value?.usuario.ehAdmin, isFalse);
    });

    test('sair limpa tudo', () async {
      final m = montar((_) async => respostaJson({}), armazenamento: ArmazenamentoFalso(sessaoDeTeste()));
      await m.autenticacao.restaurar();

      await m.autenticacao.sair();

      expect(m.autenticacao.sessao.value, isNull);
      expect(m.armazenamento.guardada, isNull);
      expect(m.autenticacao.avisoDoLogin, isNull);
    });
  });
}
