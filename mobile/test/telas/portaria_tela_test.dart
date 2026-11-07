import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/telas/portaria_tela.dart';
import 'package:mobile/widgets/leitor_camera.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../apoio/falsos.dart';

const leitorFalso = Key('leitor-falso');

Map<String, dynamic> jsonLiberado() => {
  'ingressoId': 1,
  'partida': 'México x Canadá',
  'dataJogo': '2026-12-14T16:00:00',
  'nomeSetor': 'Camarote',
  'numeroAssento': 'C01',
};

/// O que a tela entrega ao leitor: chamar esta função é o mesmo que a câmera detectar um QR.
late void Function(String codigo) lerCodigo;

Future<void> abrir(WidgetTester tester, Future<http.Response> Function(http.Request) responder) async {
  final servicos = servicosDeTeste(responder, sessao: sessaoDeTeste(perfil: 'ADMIN'));
  await servicos.autenticacao.restaurar();
  await tester.pumpWidget(
    MaterialApp(
      home: PortariaTela(
        ingressos: servicos.ingressos,
        construirLeitor: (context, aoLer) {
          lerCodigo = aoLer;
          return const SizedBox(key: leitorFalso);
        },
      ),
    ),
  );
}

Future<void> esperarResposta(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('leitura liberada: verde, com partida, setor, assento e data', (tester) async {
    await abrir(tester, (_) async => respostaJson(jsonLiberado()));

    lerCodigo('abc-1');
    await esperarResposta(tester);

    expect(find.text('ENTRADA LIBERADA'), findsOneWidget);
    expect(find.text('México x Canadá'), findsOneWidget);
    expect(find.textContaining('Camarote'), findsOneWidget);
    expect(find.textContaining('Assento C01'), findsOneWidget);
    expect(find.textContaining('14/12/2026 às 16:00'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, const Color(0xFF277234));
  });

  testWidgets('leitura recusada: vermelho, com o motivo da Api e texto escuro', (tester) async {
    await abrir(tester, (_) async => respostaJson({'erro': 'Este ingresso já foi utilizado.'}, 400));

    lerCodigo('abc-1');
    await esperarResposta(tester);

    expect(find.text('ENTRADA RECUSADA'), findsOneWidget);
    expect(find.text('Este ingresso já foi utilizado.'), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, const Color(0xFFFF4D4D));
    expect(tester.widget<Text>(find.text('ENTRADA RECUSADA')).style?.color, const Color(0xFF0D0D0D));
  });

  testWidgets('falha de rede não é recusa, e o código fica para tentar de novo', (tester) async {
    await abrir(tester, (_) async => throw http.ClientException('sem rede'));

    await tester.enterText(find.byType(TextField), 'abc-1');
    await tester.tap(find.text('VALIDAR'));
    await esperarResposta(tester);

    expect(find.text('ENTRADA RECUSADA'), findsNothing);
    expect(find.text('NÃO VALIDADO'), findsOneWidget);
    expect(find.text('Não foi possível validar. Tente de novo.'), findsOneWidget);

    await tester.tap(find.text('TENTAR DE NOVO'));
    await tester.pump();

    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, 'abc-1');
  });

  testWidgets('403 da Api também não é recusa do ingresso', (tester) async {
    await abrir(tester, (_) async => http.Response('', 403));

    lerCodigo('abc-1');
    await esperarResposta(tester);

    expect(find.text('ENTRADA RECUSADA'), findsNothing);
    expect(find.textContaining('entre de novo'), findsOneWidget);
  });

  testWidgets('duas detecções seguidas geram uma chamada, e o verde não vira vermelho', (tester) async {
    var chamadas = 0;
    await abrir(tester, (_) async {
      chamadas++;
      return chamadas == 1
          ? respostaJson(jsonLiberado())
          : respostaJson({'erro': 'Este ingresso já foi utilizado.'}, 400);
    });

    final detectar = lerCodigo;
    detectar('abc-1');
    detectar('abc-1');
    await esperarResposta(tester);
    detectar('abc-1');
    await esperarResposta(tester);

    expect(chamadas, 1);
    expect(find.text('ENTRADA LIBERADA'), findsOneWidget);
  });

  testWidgets('a câmera sai da tela durante a validação e no resultado', (tester) async {
    // A resposta fica presa até o teste soltar, para enxergar a etapa "validando".
    final resposta = Completer<http.Response>();
    await abrir(tester, (_) => resposta.future);
    expect(find.byKey(leitorFalso), findsOneWidget);

    lerCodigo('abc-1');
    await tester.pump();
    expect(find.byKey(leitorFalso), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    resposta.complete(respostaJson(jsonLiberado()));
    await esperarResposta(tester);
    expect(find.text('ENTRADA LIBERADA'), findsOneWidget);
    expect(find.byKey(leitorFalso), findsNothing);
  });

  testWidgets('o código digitado passa pela mesma chamada, sem os espaços das pontas', (tester) async {
    String? corpo;
    await abrir(tester, (pedido) async {
      corpo = pedido.body;
      return respostaJson(jsonLiberado());
    });

    await tester.enterText(find.byType(TextField), '  abc-1  ');
    await tester.tap(find.text('VALIDAR'));
    await esperarResposta(tester);

    expect(corpo, '{"codigoQR":"abc-1"}');
    expect(find.text('ENTRADA LIBERADA'), findsOneWidget);
  });

  testWidgets('campo vazio não chama a Api', (tester) async {
    var chamadas = 0;
    await abrir(tester, (_) async {
      chamadas++;
      return respostaJson(jsonLiberado());
    });

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('VALIDAR'));
    await tester.pump();

    expect(chamadas, 0);
    expect(find.text('Informe o código do ingresso.'), findsOneWidget);
  });

  testWidgets('"Ler próximo" limpa o campo e lê de novo', (tester) async {
    var chamadas = 0;
    await abrir(tester, (_) async {
      chamadas++;
      return respostaJson(jsonLiberado());
    });

    await tester.enterText(find.byType(TextField), 'abc-1');
    await tester.tap(find.text('VALIDAR'));
    await esperarResposta(tester);

    await tester.tap(find.text('LER PRÓXIMO'));
    await tester.pump();

    expect(find.byKey(leitorFalso), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, isEmpty);

    lerCodigo('abc-2');
    await esperarResposta(tester);
    expect(chamadas, 2);
  });

  testWidgets('sem permissão de câmera, a explicação indica o campo de digitar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ErroDaCamera(codigo: MobileScannerErrorCode.permissionDenied)),
    );

    expect(find.textContaining('Sem permissão para usar a câmera'), findsOneWidget);
    expect(find.textContaining('digite o código'), findsOneWidget);
  });
}
