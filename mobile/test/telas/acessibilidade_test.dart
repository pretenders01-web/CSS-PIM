import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../apoio/falsos.dart';
import '../apoio/telas_de_teste.dart';

const celular = Size(390, 844);

/// A densidade do emulador. A regra de contraste lê os pixels da tela: em densidade 1, o texto
/// pequeno sai borrado e parece ter menos contraste do que tem no aparelho.
const densidadeReal = 2.625;

/// As regras de acessibilidade que o próprio Flutter sabe conferir:
/// área de toque de 48, todo botão com rótulo e contraste do texto.
Future<void> conferirRegras(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await carregarPoppins();
  });

  final telas = <String, Future<void> Function(WidgetTester)>{
    'login': (tester) => abrirLogin(tester),
    'início com o cartão': (tester) =>
        abrirInicio(tester, (_) async => respostaJson([jsonDeIngresso()])),
    'início vazio': (tester) => abrirInicio(tester, (_) async => respostaJson(<Object>[])),
    'início com erro': (tester) => abrirInicio(tester, (_) async => throw http.ClientException('sem rede')),
    'QR válido': (tester) => abrirQr(tester),
    'QR utilizado': (tester) => abrirQr(tester, utilizado: true),
    'QR expirado': (tester) => abrirQr(tester, dataJogo: '2026-12-01T16:00:00'),
    'Portaria lendo': (tester) => abrirPortaria(tester),
    'Portaria com histórico': (tester) =>
        abrirPortaria(tester, respostaDaApi: respostaLiberada, voltarParaALeitura: true),
    'câmera da Portaria': abrirCameraDaPortaria,
    'Portaria liberada': (tester) => abrirPortaria(tester, respostaDaApi: respostaLiberada),
    'Portaria recusada': (tester) => abrirPortaria(tester, respostaDaApi: respostaRecusada),
    'Portaria sem validar': (tester) => abrirPortaria(tester, respostaDaApi: respostaSemPermissao),
  };

  telas.forEach((nome, abrir) {
    for (final (orientacao, tamanho) in const [('em pé', celular), ('deitado', Size(844, 390))]) {
      testWidgets('regras de acessibilidade: $nome, $orientacao', (tester) async {
        final semantica = tester.ensureSemantics();
        configurarAparelho(tester, tamanho, densidade: densidadeReal);

        await abrir(tester);
        await tester.pump(const Duration(milliseconds: 100));
        await conferirRegras(tester);

        await tester.pumpWidget(const SizedBox());
        semantica.dispose();
      });
    }
  });

  group('o que o leitor de tela lê', () {
    testWidgets('cartão: a frase completa do jogo, o mapa e os botões', (tester) async {
      final semantica = tester.ensureSemantics();
      configurarAparelho(tester, celular);
      await abrirInicio(tester, (_) async => respostaJson([jsonDeIngresso()]));

      expect(find.bySemanticsLabel(RegExp(r'^Próximo jogo: Brasil x Sérvia, 16/12/2026 às 16:00, AT&T Stadium, Dallas')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Mapa ilustrativo da rota até o AT&T Stadium')), findsWidgets);
      expect(find.bySemanticsLabel('VALIDAR INGRESSO'), findsOneWidget);
      expect(find.bySemanticsLabel('COMO CHEGAR'), findsOneWidget);
      // O nome do time já está na frase: a bandeira fica fora da leitura, como o alt="" da Web.
      expect(find.bySemanticsLabel(RegExp(r'^Brasil$')), findsNothing);

      await tester.pumpWidget(const SizedBox());
      semantica.dispose();
    });

    testWidgets('lista: cada ingresso diz a situação e que abre o QR', (tester) async {
      final semantica = tester.ensureSemantics();
      configurarAparelho(tester, const Size(390, 2000));
      await abrirInicio(tester, (_) async => respostaJson(ingressosVariados()));

      expect(find.bySemanticsLabel(RegExp(r'México x Canadá.*Utilizado\. Abrir o QR Code\.')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Argentina x Dinamarca.*Expirado\. Abrir o QR Code\.')), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      semantica.dispose();
    });

    testWidgets('QR: o código e a situação, que é anunciada ao mudar', (tester) async {
      final semantica = tester.ensureSemantics();
      configurarAparelho(tester, celular);
      await abrirQr(tester);

      expect(find.bySemanticsLabel('QR Code do ingresso'), findsOneWidget);
      expect(find.bySemanticsLabel('Código do QR: codigo-51'), findsOneWidget);

      final selo = find.bySemanticsLabel('Situação do ingresso: Válido');
      expect(selo, findsOneWidget);
      expect(tester.getSemantics(selo), isSemantics(isLiveRegion: true));

      await tester.pumpWidget(const SizedBox());
      semantica.dispose();
    });

    testWidgets('Portaria: o resultado é anunciado, sem depender da cor', (tester) async {
      final semantica = tester.ensureSemantics();
      configurarAparelho(tester, celular);
      await abrirPortaria(tester, respostaDaApi: respostaRecusada);

      final resultado = find.bySemanticsLabel(RegExp(r'ENTRADA RECUSADA'));
      expect(resultado, findsOneWidget);
      expect(tester.getSemantics(resultado), isSemantics(isLiveRegion: true));
      expect(find.byIcon(Icons.cancel), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      semantica.dispose();
    });

    testWidgets('Portaria: o cabeçalho, o contador e o histórico têm rótulo', (tester) async {
      final semantica = tester.ensureSemantics();
      configurarAparelho(tester, const Size(390, 1400));
      await abrirPortaria(tester, respostaDaApi: respostaLiberada, voltarParaALeitura: true);

      expect(find.bySemanticsLabel('Mundial Tickets'), findsOneWidget);
      expect(find.bySemanticsLabel('Portaria'), findsOneWidget);
      expect(find.byTooltip('Sair'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'LER QR CODE')), findsOneWidget);
      expect(find.bySemanticsLabel('Entradas liberadas nesta sessão: 1'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^12:00:00, partida Estados Unidos x Uruguai, assento B10\. Liberada\.$')),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      semantica.dispose();
    });

    testWidgets('login: os campos têm rótulo, e o erro é anunciado', (tester) async {
      final semantica = tester.ensureSemantics();
      configurarAparelho(tester, celular);
      await abrirLogin(tester);

      expect(find.bySemanticsLabel(RegExp(r'E-mail')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Senha')), findsOneWidget);
      expect(find.byTooltip('Mostrar a senha'), findsOneWidget);
      expect(find.bySemanticsLabel('Mundial Tickets'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      semantica.dispose();
    });
  });
}
