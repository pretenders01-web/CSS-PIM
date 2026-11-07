import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/modelos/ingresso.dart';
import 'package:mobile/telas/inicio_tela.dart';
import 'package:mobile/telas/qr_tela.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../apoio/falsos.dart';

const intervalo = Duration(seconds: 5);

/// Abre a tela do QR com um relógio que o teste controla.
Future<void> abrir(
  WidgetTester tester,
  Future<http.Response> Function(http.Request) responder, {
  Ingresso? ingresso,
  DateTime Function()? relogio,
}) async {
  final servicos = servicosDeTeste(responder, sessao: sessaoDeTeste());
  await servicos.autenticacao.restaurar();
  await tester.pumpWidget(
    MaterialApp(
      home: QrTela(
        ingresso: ingresso ?? ingressoDeTeste(),
        ingressos: servicos.ingressos,
        relogio: relogio ?? () => DateTime(2026, 12, 10, 12),
        intervalo: intervalo,
      ),
    ),
  );
}

/// Passa o intervalo e deixa a resposta falsa chegar.
Future<void> passarIntervalo(WidgetTester tester) async {
  await tester.pump(intervalo);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('mostra o QR do código, sobre fundo branco, e os dados do ingresso', (tester) async {
    await abrir(tester, (_) async => respostaJson([jsonDeIngresso()]));

    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qr.backgroundColor, Colors.white);
    expect(find.text('VÁLIDO'), findsOneWidget);
    expect(find.text('Brasil x Sérvia'), findsOneWidget);
    expect(find.text('A01'), findsOneWidget);
    expect(find.text('codigo-51'), findsOneWidget);
    expect(find.text('Apresente este QR Code na portaria.'), findsOneWidget);
  });

  testWidgets('o selo vira Utilizado quando a Api muda, e as consultas param', (tester) async {
    var chamadas = 0;
    await abrir(tester, (_) async {
      chamadas++;
      return respostaJson([jsonDeIngresso(utilizado: chamadas >= 2)]);
    });

    await passarIntervalo(tester);
    expect(chamadas, 1);
    expect(find.text('VÁLIDO'), findsOneWidget);

    await passarIntervalo(tester);
    expect(chamadas, 2);
    expect(find.text('UTILIZADO'), findsOneWidget);
    expect(find.text('VÁLIDO'), findsNothing);
    expect(find.text('Este ingresso já foi utilizado.'), findsOneWidget);

    await passarIntervalo(tester);
    await passarIntervalo(tester);
    expect(chamadas, 2);
  });

  testWidgets('ingresso já utilizado não consulta', (tester) async {
    var chamadas = 0;
    await abrir(tester, (_) async {
      chamadas++;
      return respostaJson([jsonDeIngresso(utilizado: true)]);
    }, ingresso: ingressoDeTeste(utilizado: true));

    await passarIntervalo(tester);

    expect(find.text('UTILIZADO'), findsOneWidget);
    expect(chamadas, 0);
  });

  testWidgets('ingresso Expirado abre com o selo e não consulta', (tester) async {
    var chamadas = 0;
    await abrir(tester, (_) async {
      chamadas++;
      return respostaJson(<Object>[]);
    }, ingresso: ingressoDeTeste(dataJogo: '2026-12-01T16:00:00'));

    await passarIntervalo(tester);

    expect(find.text('EXPIRADO'), findsOneWidget);
    expect(find.text('O jogo deste ingresso já começou.'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(chamadas, 0);
  });

  testWidgets('o jogo começar com a tela aberta muda para Expirado, e as consultas param', (tester) async {
    var agora = DateTime(2026, 12, 16, 15, 59);
    var chamadas = 0;
    await abrir(tester, (_) async {
      chamadas++;
      return respostaJson([jsonDeIngresso()]);
    }, relogio: () => agora);

    await passarIntervalo(tester);
    expect(find.text('VÁLIDO'), findsOneWidget);

    agora = DateTime(2026, 12, 16, 16);
    await passarIntervalo(tester);
    expect(find.text('EXPIRADO'), findsOneWidget);
    final depois = chamadas;

    await passarIntervalo(tester);
    expect(chamadas, depois);
  });

  testWidgets('fechar a tela cancela o timer e encerra as consultas', (tester) async {
    var chamadas = 0;
    await abrir(tester, (_) async {
      chamadas++;
      return respostaJson([jsonDeIngresso()]);
    });

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await passarIntervalo(tester);

    // Se o timer ficasse ativo, o próprio teste falharia com "A Timer is still pending".
    expect(chamadas, 0);
  });

  testWidgets('falha de rede mantém o QR, avisa e continua tentando', (tester) async {
    var chamadas = 0;
    await abrir(tester, (_) async {
      chamadas++;
      if (chamadas == 1) throw http.ClientException('sem rede');
      return respostaJson([jsonDeIngresso()]);
    });

    await passarIntervalo(tester);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.textContaining('Sem conexão'), findsOneWidget);

    await passarIntervalo(tester);
    expect(chamadas, 2);
    expect(find.textContaining('Sem conexão'), findsNothing);
  });

  testWidgets('em segundo plano não consulta, e ao voltar consulta na hora', (tester) async {
    var chamadas = 0;
    await abrir(tester, (_) async {
      chamadas++;
      return respostaJson([jsonDeIngresso(utilizado: true)]);
    });

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(intervalo * 3);
    expect(chamadas, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));

    expect(chamadas, 1);
    expect(find.text('UTILIZADO'), findsOneWidget);
  });

  testWidgets('o botão do cartão abre o QR pelo Hero, e a tela inicial recarrega ao voltar', (tester) async {
    var chamadas = 0;
    final servicos = servicosDeTeste((_) async {
      chamadas++;
      return respostaJson([jsonDeIngresso()]);
    }, sessao: sessaoDeTeste());
    await servicos.autenticacao.restaurar();
    await tester.pumpWidget(
      MaterialApp(
        home: InicioTela(
          autenticacao: servicos.autenticacao,
          ingressos: servicos.ingressos,
          relogio: () => DateTime(2026, 12, 10, 12),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(chamadas, 1);

    await tester.ensureVisible(find.text('VALIDAR INGRESSO'));
    await tester.pump();
    await tester.tap(find.text('VALIDAR INGRESSO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // No meio do voo, o Hero existe e nada estourou.
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(QrTela), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(QrTela), findsNothing);
    expect(chamadas, 2);
  });
}
