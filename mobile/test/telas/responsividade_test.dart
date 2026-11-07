import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../apoio/falsos.dart';
import '../apoio/telas_de_teste.dart';

/// Do celular pequeno ao grande, em retrato.
const aparelhos = {
  '320x568': Size(320, 568),
  '360x640': Size(360, 640),
  '390x844': Size(390, 844),
  '430x932': Size(430, 932),
};

const escalasDeFonte = [1.0, 1.3, 2.0];

/// Cada tela é aberta em cada aparelho e em cada escala de fonte.
/// Um estouro de layout é um erro do Flutter, e faz o teste falhar sozinho.
final Map<String, Future<void> Function(WidgetTester)> telas = {
  'login': (tester) => abrirLogin(tester),
  'login com erros nos campos': (tester) => abrirLogin(tester, comErros: true),
  'início com o cartão e a lista': (tester) async {
    await abrirInicio(tester, (_) async => respostaJson(ingressosVariados()));
    // Rola até o fim, para montar também os itens que estavam fora da tela.
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump(const Duration(milliseconds: 100));
  },
  'início sem próximo jogo': (tester) =>
      abrirInicio(tester, (_) async => respostaJson([jsonDeIngresso(utilizado: true)])),
  'início vazio': (tester) => abrirInicio(tester, (_) async => respostaJson(<Object>[])),
  'início com erro': (tester) => abrirInicio(tester, (_) async => throw http.ClientException('sem rede')),
  'QR válido': (tester) => abrirQr(tester),
  'QR utilizado': (tester) => abrirQr(tester, utilizado: true),
  'QR expirado': (tester) => abrirQr(tester, dataJogo: '2026-12-01T16:00:00'),
  'Portaria lendo': (tester) => abrirPortaria(tester),
  'Portaria com histórico': (tester) async {
    await abrirPortaria(tester, respostaDaApi: respostaLiberada, voltarParaALeitura: true);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
    await tester.pump(const Duration(milliseconds: 100));
  },
  'Portaria com recusa no histórico': (tester) =>
      abrirPortaria(tester, respostaDaApi: respostaRecusada, voltarParaALeitura: true),
  'câmera da Portaria': abrirCameraDaPortaria,
  'Portaria liberada': (tester) => abrirPortaria(tester, respostaDaApi: respostaLiberada),
  'Portaria recusada': (tester) => abrirPortaria(tester, respostaDaApi: respostaRecusada),
  'Portaria sem validar': (tester) => abrirPortaria(tester, respostaDaApi: respostaSemPermissao),
};

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await carregarPoppins();
  });

  telas.forEach((nomeDaTela, abrir) {
    aparelhos.forEach((nomeDoAparelho, tamanho) {
      for (final escala in escalasDeFonte) {
        testWidgets('$nomeDaTela em $nomeDoAparelho, fonte $escala', (tester) async {
          configurarAparelho(tester, tamanho, escalaDeFonte: escala);

          await abrir(tester);

          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    });
  });

  testWidgets('o cartão cresce com a fonte, em vez de cortar o conteúdo', (tester) async {
    configurarAparelho(tester, const Size(390, 844));
    await abrirInicio(tester, (_) async => respostaJson([jsonDeIngresso()]));
    final normal = tester.getSize(find.textContaining('VALIDAR INGRESSO').first);
    await tester.pumpWidget(const SizedBox());

    configurarAparelho(tester, const Size(390, 844), escalaDeFonte: 2);
    await abrirInicio(tester, (_) async => respostaJson([jsonDeIngresso()]));
    final grande = tester.getSize(find.textContaining('VALIDAR INGRESSO').first);

    expect(grande.height, greaterThan(normal.height));
    await tester.pumpWidget(const SizedBox());
  });
}
