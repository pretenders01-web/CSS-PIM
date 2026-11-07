import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:mobile/servicos/cliente_api.dart';
import 'package:mobile/servicos/erros_api.dart';
import 'package:mobile/servicos/ingresso_servico.dart';

import '../apoio/falsos.dart';

IngressoServico servicoCom(MockClientHandler responder) {
  final api = ClienteApi(cliente: MockClient(responder), enderecoBase: enderecoDeTeste);
  final sessao = sessaoDeTeste();
  api.lerSessao = () => sessao;
  return IngressoServico(api: api);
}

void main() {
  group('listarMeusIngressos', () {
    test('lê a lista', () async {
      final lista = await servicoCom(
        (pedido) async {
          expect(pedido.url.path, '/api/vendas/meus-ingressos');
          return respostaJson([jsonDeIngresso(), jsonDeIngresso(ingressoId: 52)]);
        },
      ).listarMeusIngressos();

      expect(lista.map((i) => i.ingressoId), [51, 52]);
    });

    test('resposta fora do formato vira ApiException', () async {
      final servico = servicoCom((_) async => respostaJson({'nao': 'é lista'}));

      await expectLater(servico.listarMeusIngressos(), throwsA(isA<ApiException>()));
    });

    test('item sem campo obrigatório vira ApiException', () async {
      final servico = servicoCom((_) async => respostaJson([{'ingressoId': 1}]));

      await expectLater(servico.listarMeusIngressos(), throwsA(isA<ApiException>()));
    });
  });

  group('consultar', () {
    test('encontra o ingresso na lista', () async {
      final servico = servicoCom(
        (_) async => respostaJson([jsonDeIngresso(ingressoId: 1), jsonDeIngresso(ingressoId: 2, utilizado: true)]),
      );

      final ingresso = await servico.consultar(2);

      expect(ingresso?.ingressoId, 2);
      expect(ingresso?.utilizado, isTrue);
    });

    test('devolve null se o ingresso não estiver na lista', () async {
      final servico = servicoCom((_) async => respostaJson([jsonDeIngresso(ingressoId: 1)]));

      expect(await servico.consultar(99), isNull);
    });
  });
}
