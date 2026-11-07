import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/telas/inicio_tela.dart';
import 'package:mobile/widgets/cartao_ingresso.dart';
import 'package:mobile/widgets/cartao_proximo_jogo.dart';
import 'package:mobile/widgets/mapa_rota.dart';

import '../apoio/falsos.dart';

final agoraDeTeste = DateTime(2026, 12, 10, 12);

/// Usa pump com duração, e não pumpAndSettle: a animação do mapa se repete e nunca "assenta".
Future<void> abrir(
  WidgetTester tester,
  Future<http.Response> Function(http.Request) responder, {
  String perfil = 'CLIENTE',
  Future<bool> Function(Uri)? abrirLink,
}) async {
  final servicos = servicosDeTeste(responder, sessao: sessaoDeTeste(perfil: perfil));
  await servicos.autenticacao.restaurar();
  await tester.pumpWidget(
    MaterialApp(
      home: InicioTela(
        autenticacao: servicos.autenticacao,
        ingressos: servicos.ingressos,
        relogio: () => agoraDeTeste,
        abrirLink: abrirLink ?? (_) async => true,
      ),
    ),
  );
}

Future<void> esperarCarregar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('mostra o carregando e depois o cartão com os campos', (tester) async {
    await abrir(tester, (_) async => respostaJson([jsonDeIngresso()]));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await esperarCarregar(tester);

    expect(find.byType(CartaoProximoJogo), findsOneWidget);
    expect(find.text('Brasil'), findsOneWidget);
    expect(find.text('Sérvia'), findsOneWidget);
    expect(find.text('Arquibancada Inferior'), findsOneWidget);
    expect(find.text('A01'), findsOneWidget);
    expect(find.text('16/12/2026 às 16:00'), findsOneWidget);
    expect(find.text('AT&T Stadium, Dallas'), findsOneWidget);
    expect(find.text('VÁLIDO'), findsOneWidget);
    expect(find.byType(MapaRota), findsOneWidget);
    expect(find.text('VALIDAR INGRESSO'), findsOneWidget);
    expect(find.text('COMO CHEGAR'), findsOneWidget);
  });

  testWidgets('sem ingressos, mostra o estado vazio', (tester) async {
    await abrir(tester, (_) async => respostaJson(<Object>[]));
    await esperarCarregar(tester);

    expect(find.text('Você ainda não tem ingressos'), findsOneWidget);
    expect(find.byType(CartaoProximoJogo), findsNothing);
  });

  testWidgets('sem próximo jogo: mensagem no lugar do cartão e a lista abaixo', (tester) async {
    await abrir(
      tester,
      (_) async => respostaJson([
        jsonDeIngresso(ingressoId: 1, utilizado: true),
        jsonDeIngresso(ingressoId: 2, dataJogo: '2026-12-01T16:00:00'),
      ]),
    );
    await esperarCarregar(tester);

    expect(find.text('Nenhum próximo jogo'), findsOneWidget);
    expect(find.byType(CartaoProximoJogo), findsNothing);
    expect(find.byType(CartaoIngresso), findsNWidgets(2));
    expect(find.text('UTILIZADO'), findsOneWidget);
    expect(find.text('EXPIRADO'), findsOneWidget);
  });

  testWidgets('os outros ingressos ficam abaixo do cartão', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await abrir(
      tester,
      (_) async => respostaJson([
        jsonDeIngresso(ingressoId: 1, timeA: 'México', timeB: 'Canadá', dataJogo: '2026-12-14T16:00:00'),
        jsonDeIngresso(ingressoId: 2, timeA: 'França', timeB: 'Chile', dataJogo: '2026-12-18T16:00:00'),
      ]),
    );
    await esperarCarregar(tester);

    expect(find.byType(CartaoProximoJogo), findsOneWidget);
    expect(find.text('México'), findsOneWidget);
    expect(find.text('Outros ingressos'), findsOneWidget);
    expect(find.byType(CartaoIngresso), findsOneWidget);
    expect(find.text('França x Chile'), findsOneWidget);
  });

  testWidgets('erro mostra a mensagem, e "tentar de novo" carrega', (tester) async {
    var tentativas = 0;
    await abrir(tester, (_) async {
      tentativas++;
      if (tentativas == 1) throw http.ClientException('sem rede');
      return respostaJson([jsonDeIngresso()]);
    });
    await esperarCarregar(tester);

    expect(find.textContaining('Não foi possível falar com o servidor'), findsOneWidget);

    await tester.tap(find.text('TENTAR DE NOVO'));
    await esperarCarregar(tester);

    expect(tentativas, 2);
    expect(find.byType(CartaoProximoJogo), findsOneWidget);
  });

  testWidgets('falha ao atualizar mantém os dados na tela', (tester) async {
    var tentativas = 0;
    await abrir(tester, (_) async {
      tentativas++;
      if (tentativas > 1) throw http.ClientException('sem rede');
      return respostaJson([jsonDeIngresso()]);
    });
    await esperarCarregar(tester);

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(tentativas, 2);
    expect(find.byType(CartaoProximoJogo), findsOneWidget);
    expect(find.textContaining('Não foi possível falar com o servidor'), findsOneWidget);
  });

  testWidgets('a tela do torcedor não tem a Portaria, mesmo que o perfil seja ADMIN', (tester) async {
    await abrir(tester, (_) async => respostaJson([jsonDeIngresso()]));
    await esperarCarregar(tester);
    expect(find.byTooltip('Portaria'), findsNothing);
    expect(find.byTooltip('Sair'), findsOneWidget);

    await abrir(tester, (_) async => respostaJson([jsonDeIngresso()]), perfil: 'ADMIN');
    await esperarCarregar(tester);
    expect(find.byTooltip('Portaria'), findsNothing);
    expect(find.byIcon(Icons.qr_code_scanner), findsNothing);
  });

  testWidgets('"Como chegar" abre o estádio e a cidade do cartão', (tester) async {
    Uri? aberto;
    await abrir(
      tester,
      (_) async => respostaJson([jsonDeIngresso()]),
      abrirLink: (endereco) async {
        aberto = endereco;
        return true;
      },
    );
    await esperarCarregar(tester);

    await tester.ensureVisible(find.text('COMO CHEGAR'));
    await tester.pump();
    await tester.tap(find.text('COMO CHEGAR'));
    await tester.pump();

    expect(aberto?.queryParameters['query'], 'AT&T Stadium, Dallas');
  });

  testWidgets('sem como abrir o mapa, mostra um aviso', (tester) async {
    await abrir(tester, (_) async => respostaJson([jsonDeIngresso()]), abrirLink: (_) async => false);
    await esperarCarregar(tester);

    await tester.ensureVisible(find.text('COMO CHEGAR'));
    await tester.pump();
    await tester.tap(find.text('COMO CHEGAR'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Não foi possível abrir o mapa.'), findsOneWidget);
  });

  testWidgets('o cartão tem altura mínima de metade da tela', (tester) async {
    await abrir(tester, (_) async => respostaJson([jsonDeIngresso()]));
    await esperarCarregar(tester);

    final alturaDaTela = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(tester.getSize(find.byType(CartaoProximoJogo)).height, greaterThanOrEqualTo(alturaDaTela * 0.5));
  });

  testWidgets('com animações reduzidas, o mapa fica parado no desenho pronto', (tester) async {
    final servicos = servicosDeTeste((_) async => respostaJson([jsonDeIngresso()]), sessao: sessaoDeTeste());
    await servicos.autenticacao.restaurar();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true, size: Size(800, 900)),
        child: MaterialApp(
          home: InicioTela(
            autenticacao: servicos.autenticacao,
            ingressos: servicos.ingressos,
            relogio: () => agoraDeTeste,
          ),
        ),
      ),
    );
    await esperarCarregar(tester);

    final pintor = tester.widget<CustomPaint>(
      find.descendant(of: find.byType(MapaRota), matching: find.byType(CustomPaint)),
    ).painter! as PintorDaRota;

    expect(pintor.animacao.value, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
