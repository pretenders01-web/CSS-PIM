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
}
