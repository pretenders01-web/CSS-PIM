import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/modelos/ingresso_validado.dart';
import 'package:mobile/servicos/autenticacao_servico.dart';
import 'package:mobile/telas/leitor_qr_tela.dart';
import 'package:mobile/telas/portaria_tela.dart';
import 'package:mobile/widgets/leitor_camera.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../apoio/falsos.dart';

const leitorFalso = Key('leitor-falso');

Map<String, dynamic> jsonLiberado({String partida = 'México x Canadá', String assento = 'C01'}) => {
  'ingressoId': 1,
  'partida': partida,
  'dataJogo': '2026-12-14T16:00:00',
  'nomeSetor': 'Camarote',
  'numeroAssento': assento,
};

/// O que a câmera entrega: chamar esta função é o mesmo que ela detectar um QR.
late void Function(String codigo) lerCodigo;

Future<AutenticacaoServico> abrir(
  WidgetTester tester,
  Future<http.Response> Function(http.Request) responder, {
  DateTime Function()? relogio,
  ArmazenamentoFalso? armazenamento,
  TransitionBuilder? envolver,
}) async {
  final guarda = armazenamento ?? ArmazenamentoFalso(sessaoDeTeste(perfil: 'ADMIN'));
  final servicos = servicosDeTeste(responder, armazenamento: guarda);
  await servicos.autenticacao.restaurar();
  await tester.pumpWidget(
    MaterialApp(
      builder: envolver,
      home: PortariaTela(
        autenticacao: servicos.autenticacao,
        ingressos: servicos.ingressos,
        relogio: relogio ?? () => DateTime(2026, 12, 10, 16, 5, 12),
        construirLeitor: (context, aoLer) {
          lerCodigo = aoLer;
          return const SizedBox.expand(key: leitorFalso);
        },
      ),
    ),
  );
  return servicos.autenticacao;
}

/// Toca em "Ler QR Code" e deixa a câmera (falsa) aberta.
Future<void> abrirCamera(WidgetTester tester) async {
  await tester.tap(find.text('LER QR CODE'));
  await tester.pumpAndSettle();
  expect(find.byType(LeitorQrTela), findsOneWidget);
}

Future<void> digitarEValidar(WidgetTester tester, String codigo) async {
  await tester.enterText(find.byType(TextField), codigo);
  await tester.ensureVisible(find.text('VALIDAR'));
  await tester.pump();
  await tester.tap(find.text('VALIDAR'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

/// A contagem da volta automática fica ativa no resultado: o teste precisa desmontar a tela no fim.
Future<void> fechar(WidgetTester tester) => tester.pumpWidget(const SizedBox());

void main() {
  group('cabeçalho e tela de leitura', () {
    testWidgets('mostra o logo, o título, o botão de sair e o botão grande', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);

      await abrir(tester, (_) async => respostaJson({}));

      expect(find.bySemanticsLabel('Mundial Tickets'), findsOneWidget);
      expect(find.text('Portaria'), findsOneWidget);
      expect(find.byTooltip('Sair'), findsOneWidget);
      expect(find.text('LER QR CODE'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Código do ingresso'), findsOneWidget);
      expect(tester.getSize(find.ancestor(of: find.text('LER QR CODE'), matching: find.byType(ElevatedButton))).height, greaterThanOrEqualTo(80));
    });

    testWidgets('a câmera só abre pelo botão, e é só então que o Android pede a permissão', (tester) async {
      await abrir(tester, (_) async => respostaJson({}));
      expect(find.byKey(leitorFalso), findsNothing);

      await abrirCamera(tester);
      expect(find.byKey(leitorFalso), findsOneWidget);
    });

    testWidgets('sair encerra a sessão', (tester) async {
      final guarda = ArmazenamentoFalso(sessaoDeTeste(perfil: 'ADMIN'));
      final autenticacao = await abrir(tester, (_) async => respostaJson({}), armazenamento: guarda);

      await tester.tap(find.byTooltip('Sair'));
      await tester.pump();

      expect(autenticacao.sessao.value, isNull);
      expect(guarda.guardada, isNull);
    });
  });

  group('leitura pela câmera', () {
    testWidgets('liberada: fecha a câmera e mostra o verde, com partida, setor, assento e data', (tester) async {
      await abrir(tester, (_) async => respostaJson(jsonLiberado()));
      await abrirCamera(tester);

      lerCodigo('abc-1');
      await tester.pumpAndSettle();

      expect(find.byType(LeitorQrTela), findsNothing);
      expect(find.text('ENTRADA LIBERADA'), findsOneWidget);
      expect(find.text('México x Canadá'), findsOneWidget);
      expect(find.textContaining('Camarote'), findsOneWidget);
      expect(find.textContaining('Assento C01'), findsOneWidget);
      expect(find.textContaining('14/12/2026 às 16:00'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, const Color(0xFF277234));
      await fechar(tester);
    });

    testWidgets('recusada: vermelho, com o motivo da Api e texto escuro', (tester) async {
      await abrir(tester, (_) async => respostaJson({'erro': 'Este ingresso já foi utilizado.'}, 400));
      await abrirCamera(tester);

      lerCodigo('abc-1');
      await tester.pumpAndSettle();

      expect(find.text('ENTRADA RECUSADA'), findsOneWidget);
      expect(find.text('Este ingresso já foi utilizado.'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, const Color(0xFFFF4D4D));
      expect(tester.widget<Text>(find.text('ENTRADA RECUSADA')).style?.color, const Color(0xFF0D0D0D));
      await fechar(tester);
    });

    testWidgets('duas detecções seguidas geram uma chamada, e o verde não vira vermelho', (tester) async {
      var chamadas = 0;
      await abrir(tester, (_) async {
        chamadas++;
        return chamadas == 1 ? respostaJson(jsonLiberado()) : respostaJson({'erro': 'Este ingresso já foi utilizado.'}, 400);
      });
      await abrirCamera(tester);

      final detectar = lerCodigo;
      detectar('abc-1');
      detectar('abc-1');
      await tester.pumpAndSettle();

      expect(chamadas, 1);
      expect(find.text('ENTRADA LIBERADA'), findsOneWidget);
      await fechar(tester);
    });

    testWidgets('fechar a câmera sem ler não chama a Api', (tester) async {
      var chamadas = 0;
      await abrir(tester, (_) async {
        chamadas++;
        return respostaJson(jsonLiberado());
      });
      await abrirCamera(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(chamadas, 0);
      expect(find.text('LER QR CODE'), findsOneWidget);
    });

    testWidgets('sem permissão de câmera, a explicação indica o campo de digitar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ErroDaCamera(codigo: MobileScannerErrorCode.permissionDenied)),
      );

      expect(find.textContaining('Sem permissão para usar a câmera'), findsOneWidget);
      expect(find.textContaining('volte e digite o código'), findsOneWidget);
    });
  });

  group('código digitado', () {
    testWidgets('passa pela mesma chamada, sem os espaços das pontas', (tester) async {
      String? corpo;
      await abrir(tester, (pedido) async {
        corpo = pedido.body;
        return respostaJson(jsonLiberado());
      });

      await digitarEValidar(tester, '  abc-1  ');

      expect(corpo, '{"codigoQR":"abc-1"}');
      expect(find.text('ENTRADA LIBERADA'), findsOneWidget);
      await fechar(tester);
    });

    testWidgets('campo vazio não chama a Api', (tester) async {
      var chamadas = 0;
      await abrir(tester, (_) async {
        chamadas++;
        return respostaJson(jsonLiberado());
      });

      await digitarEValidar(tester, '   ');

      expect(chamadas, 0);
      expect(find.text('Informe o código do ingresso.'), findsOneWidget);
    });

    testWidgets('durante a validação, o botão da câmera e o campo ficam travados', (tester) async {
      final resposta = Completer<http.Response>();
      await abrir(tester, (_) => resposta.future);

      await digitarEValidar(tester, 'abc-1');

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      expect(
        tester.widget<ElevatedButton>(find.ancestor(of: find.text('LER QR CODE'), matching: find.byType(ElevatedButton))).onPressed,
        isNull,
      );

      resposta.complete(respostaJson(jsonLiberado()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('ENTRADA LIBERADA'), findsOneWidget);
      await fechar(tester);
    });
  });

  group('falhas que não são recusa', () {
    testWidgets('falha de rede fica neutra, e o código fica no campo para tentar de novo', (tester) async {
      await abrir(tester, (_) async => throw http.ClientException('sem rede'));

      await digitarEValidar(tester, 'abc-1');

      expect(find.text('ENTRADA RECUSADA'), findsNothing);
      expect(find.text('NÃO VALIDADO'), findsOneWidget);
      expect(find.text('Não foi possível validar. Tente de novo.'), findsOneWidget);

      await tester.tap(find.text('TENTAR DE NOVO'));
      await tester.pump();

      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, 'abc-1');
    });

    testWidgets('o código lido pela câmera também fica no campo', (tester) async {
      await abrir(tester, (_) async => throw http.ClientException('sem rede'));
      await abrirCamera(tester);

      lerCodigo('abc-da-camera');
      await tester.pumpAndSettle();
      await tester.tap(find.text('TENTAR DE NOVO'));
      await tester.pump();

      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, 'abc-da-camera');
    });

    testWidgets('403 da Api também não é recusa do ingresso', (tester) async {
      await abrir(tester, (_) async => http.Response('', 403));

      await digitarEValidar(tester, 'abc-1');

      expect(find.text('ENTRADA RECUSADA'), findsNothing);
      expect(find.textContaining('entre de novo'), findsOneWidget);
      await fechar(tester);
    });
  });

  group('volta para a leitura', () {
    testWidgets('volta sozinha depois de 5 segundos, com a contagem na tela', (tester) async {
      await abrir(tester, (_) async => respostaJson(jsonLiberado()));
      await digitarEValidar(tester, 'abc-1');

      expect(find.text('Voltando à leitura em 5 s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Voltando à leitura em 4 s'), findsOneWidget);
      expect(find.text('ENTRADA LIBERADA'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('ENTRADA LIBERADA'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('ENTRADA LIBERADA'), findsNothing);
      expect(find.text('LER QR CODE'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, isEmpty);
    });

    testWidgets('volta à tela de leitura, e não reabre a câmera, com o mesmo QR ainda na frente dela', (tester) async {
      await abrir(tester, (_) async => respostaJson(jsonLiberado()));
      await abrirCamera(tester);

      lerCodigo('abc-1');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.byType(LeitorQrTela), findsNothing);
      expect(find.byKey(leitorFalso), findsNothing);
      expect(find.text('LER QR CODE'), findsOneWidget);
    });

    testWidgets('o botão volta na hora, e a contagem não dispara depois', (tester) async {
      var chamadas = 0;
      await abrir(tester, (_) async {
        chamadas++;
        return respostaJson(jsonLiberado());
      });
      await digitarEValidar(tester, 'abc-1');

      await tester.tap(find.text('LER PRÓXIMO'));
      await tester.pump();
      expect(find.text('LER QR CODE'), findsOneWidget);

      // Se a contagem continuasse viva, o próximo resultado voltaria antes da hora.
      await digitarEValidar(tester, 'abc-2');
      expect(chamadas, 2);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('ENTRADA LIBERADA'), findsOneWidget);
      await fechar(tester);
    });

    testWidgets('com leitor de tela, não volta sozinha, para não cortar a leitura', (tester) async {
      await abrir(
        tester,
        (_) async => respostaJson(jsonLiberado()),
        envolver: (context, tela) => MediaQuery(
          data: MediaQuery.of(context).copyWith(accessibleNavigation: true),
          child: tela!,
        ),
      );
      await digitarEValidar(tester, 'abc-1');

      expect(find.textContaining('Voltando à leitura'), findsNothing);

      await tester.pump(const Duration(seconds: 30));
      expect(find.text('ENTRADA LIBERADA'), findsOneWidget);

      await tester.tap(find.text('LER PRÓXIMO'));
      await tester.pump();
      expect(find.text('LER QR CODE'), findsOneWidget);
    });
  });

  group('histórico e contador', () {
    testWidgets('começa vazio, com o contador em zero', (tester) async {
      await abrir(tester, (_) async => respostaJson({}));

      expect(find.text('Nenhuma validação ainda.'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('registra horário, partida, assento e resultado, do mais recente ao mais antigo', (tester) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);

      var agora = DateTime(2026, 12, 10, 16, 5, 12);
      var chamadas = 0;
      await abrir(tester, (_) async {
        chamadas++;
        return chamadas == 1
            ? respostaJson(jsonLiberado(partida: 'Brasil x Sérvia', assento: 'A01'))
            : respostaJson({'erro': 'Código não encontrado: este QR não pertence a nenhum ingresso.'}, 400);
      }, relogio: () => agora);

      await digitarEValidar(tester, 'abc-1');
      await tester.tap(find.text('LER PRÓXIMO'));
      await tester.pump();

      agora = DateTime(2026, 12, 10, 16, 6, 40);
      await digitarEValidar(tester, 'nao-existe');
      await tester.tap(find.text('LER PRÓXIMO'));
      await tester.pump();

      expect(find.text('16:05:12'), findsOneWidget);
      expect(find.text('Brasil x Sérvia'), findsOneWidget);
      expect(find.text('Assento A01'), findsOneWidget);
      expect(find.text('LIBERADA'), findsOneWidget);
      expect(find.text('16:06:40'), findsOneWidget);
      expect(find.text('RECUSADA'), findsOneWidget);
      expect(find.text('Código não encontrado: este QR não pertence a nenhum ingresso.'), findsOneWidget);

      // A recusa de um código desconhecido não tem partida: a Api só devolve o motivo.
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Assento —'), findsOneWidget);

      // O mais recente fica em cima.
      expect(tester.getTopLeft(find.text('16:06:40')).dy, lessThan(tester.getTopLeft(find.text('16:05:12')).dy));
    });

    testWidgets('a recusa de um código já liberado reaproveita a partida do histórico', (tester) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);

      var chamadas = 0;
      await abrir(tester, (_) async {
        chamadas++;
        return chamadas == 1
            ? respostaJson(jsonLiberado(partida: 'Brasil x Sérvia', assento: 'A01'))
            : respostaJson({'erro': 'Este ingresso já foi utilizado.'}, 400);
      });

      await digitarEValidar(tester, 'abc-1');
      await tester.tap(find.text('LER PRÓXIMO'));
      await tester.pump();
      await digitarEValidar(tester, 'abc-1');
      await tester.tap(find.text('LER PRÓXIMO'));
      await tester.pump();

      expect(find.text('Brasil x Sérvia'), findsNWidgets(2));
      expect(find.text('Assento A01'), findsNWidgets(2));
      expect(find.text('RECUSADA'), findsOneWidget);
    });

    testWidgets('o contador só soma as entradas liberadas', (tester) async {
      var chamadas = 0;
      await abrir(tester, (_) async {
        chamadas++;
        return switch (chamadas) {
          1 || 3 => respostaJson(jsonLiberado()),
          2 => respostaJson({'erro': 'Este ingresso já foi utilizado.'}, 400),
          _ => throw http.ClientException('sem rede'),
        };
      });

      for (var i = 1; i <= 4; i++) {
        await digitarEValidar(tester, 'abc-$i');
        await tester.tap(find.textContaining(i == 4 ? 'TENTAR DE NOVO' : 'LER PRÓXIMO'));
        await tester.pump();
      }

      expect(find.bySemanticsLabel('Entradas liberadas nesta sessão: 2'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('o histórico fica só em memória: nada vai para o armazenamento e some ao abrir de novo', (tester) async {
      final sessao = sessaoDeTeste(perfil: 'ADMIN');
      final guarda = ArmazenamentoFalso(sessao);
      await abrir(tester, (_) async => respostaJson(jsonLiberado()), armazenamento: guarda);

      await digitarEValidar(tester, 'abc-1');
      await tester.tap(find.text('LER PRÓXIMO'));
      await tester.pump();

      expect(find.text('Nenhuma validação ainda.'), findsNothing);
      expect(guarda.guardada, same(sessao));
      expect(guarda.guardada!.toJson().toString(), isNot(contains('abc-1')));

      await fechar(tester);
      await abrir(tester, (_) async => respostaJson(jsonLiberado()), armazenamento: guarda);
      expect(find.text('Nenhuma validação ainda.'), findsOneWidget);
    });
  });

  test('IngressoValidado com assento nulo não quebra o registro', () {
    final validado = IngressoValidado.fromJson({...jsonLiberado(), 'numeroAssento': null});

    expect(validado.numeroAssento, isNull);
  });
}
