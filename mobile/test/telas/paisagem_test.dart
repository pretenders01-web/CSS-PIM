import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/app.dart';
import 'package:mobile/telas/inicio_tela.dart';
import 'package:mobile/telas/leitor_qr_tela.dart';
import 'package:mobile/telas/login_tela.dart';
import 'package:mobile/telas/portaria_tela.dart';
import 'package:mobile/telas/qr_tela.dart';
import 'package:mobile/util/layout.dart';
import 'package:mobile/widgets/cartao_ingresso.dart';
import 'package:mobile/widgets/mapa_rota.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../apoio/falsos.dart';
import '../apoio/telas_de_teste.dart';

const emPe = Size(390, 844);
const deitado = Size(844, 390);

/// Gira o aparelho no meio do teste, como o Android faz: só o tamanho da tela muda.
Future<void> girar(WidgetTester tester, Size tamanho) async {
  tester.view.physicalSize = tamanho * tester.view.devicePixelRatio;
  await tester.pump();
}

Map<String, dynamic> jsonLiberado() => {
  'ingressoId': 1,
  'partida': 'Brasil x Sérvia',
  'dataJogo': '2026-12-16T16:00:00',
  'nomeSetor': 'Camarote',
  'numeroAssento': 'C01',
};

/// Conta quantas vezes o leitor foi montado: uma câmera remontada seria uma câmera reiniciada.
class LeitorQueConta extends StatefulWidget {
  const LeitorQueConta({super.key, required this.aoMontar});

  final VoidCallback aoMontar;

  @override
  State<LeitorQueConta> createState() => _LeitorQueContaState();
}

class _LeitorQueContaState extends State<LeitorQueConta> {
  @override
  void initState() {
    super.initState();
    widget.aoMontar();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

/// O emulador deitado: 2424x1080, com a barra de status, o recorte da câmera e a barra de gestos.
const densidadeDoEmulador = 2.625;
const larguraDoEmulador = 2424 / densidadeDoEmulador;
const fimDaAreaUtil = (1080 - 63) / densidadeDoEmulador;

void configurarEmuladorDeitado(WidgetTester tester) {
  configurarAparelho(
    tester,
    const Size(larguraDoEmulador, 1080 / densidadeDoEmulador),
    densidade: densidadeDoEmulador,
  );
  tester.view.padding = const FakeViewPadding(left: 142, top: 137, bottom: 63);
  addTearDown(tester.view.resetPadding);
}

/// Quanto ainda dá para rolar, na rolagem que tem mais a rolar. Zero: tudo cabe na tela.
double oQueFaltaRolar(WidgetTester tester) {
  return tester
      .stateList<ScrollableState>(find.byType(Scrollable))
      .map((rolagem) => rolagem.position.maxScrollExtent)
      .fold(0, math.max);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await carregarPoppins();
  });

  group('no emulador deitado, o principal cabe sem rolar', () {
    testWidgets('o login', (tester) async {
      configurarEmuladorDeitado(tester);
      await abrirLogin(tester);

      expect(oQueFaltaRolar(tester), 0);
    });

    testWidgets('o cartão do próximo jogo, com os dois botões', (tester) async {
      configurarEmuladorDeitado(tester);
      await abrirInicio(tester, (_) async => respostaJson([jsonDeIngresso()]));

      expect(tester.getRect(find.text('COMO CHEGAR')).bottom, lessThanOrEqualTo(fimDaAreaUtil));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('o QR e os dados', (tester) async {
      configurarEmuladorDeitado(tester);
      await abrirQr(tester);

      expect(oQueFaltaRolar(tester), 0);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a leitura da Portaria, com o botão VALIDAR', (tester) async {
      configurarEmuladorDeitado(tester);
      await abrirPortaria(tester);

      expect(tester.getRect(find.text('VALIDAR')).bottom, lessThanOrEqualTo(fimDaAreaUtil));
      expect(oQueFaltaRolar(tester), 0);
    });
  });

  test('a orientação não está mais travada em retrato', () {
    expect(orientacoesDoApp, contains(DeviceOrientation.portraitUp));
    expect(orientacoesDoApp, contains(DeviceOrientation.landscapeLeft));
    expect(orientacoesDoApp, contains(DeviceOrientation.landscapeRight));
  });

  group('login deitado', () {
    testWidgets('fica centralizado, com largura máxima', (tester) async {
      configurarAparelho(tester, const Size(932, 430));
      await abrirLogin(tester);

      final formulario = tester.getRect(find.byType(Form));
      expect(formulario.width, lessThanOrEqualTo(420));
      expect(formulario.center.dx, closeTo(932 / 2, 1));
    });

    testWidgets('com o teclado aberto, o campo em foco continua na tela', (tester) async {
      configurarAparelho(tester, deitado);
      await abrirLogin(tester);

      // O teclado encolhe a altura útil, como no aparelho.
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.view.resetViewInsets);
      await tester.tap(find.widgetWithText(TextFormField, 'Senha'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.widgetWithText(TextFormField, 'Senha')).bottom,
        lessThanOrEqualTo(390 - 220),
      );
    });

    testWidgets('girar mantém o que foi digitado e o foco', (tester) async {
      configurarAparelho(tester, emPe);
      await abrirLogin(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), 'ana@exemplo.com');
      await tester.tap(find.widgetWithText(TextFormField, 'E-mail'));
      await tester.pump();
      final foco = tester.binding.focusManager.primaryFocus;

      await girar(tester, deitado);

      expect(find.text('ana@exemplo.com'), findsOneWidget);
      expect(tester.binding.focusManager.primaryFocus, same(foco));
    });
  });

  group('início deitado', () {
    testWidgets('os dados ficam de um lado, e o mapa e os botões do outro', (tester) async {
      configurarAparelho(tester, deitado);
      await abrirInicio(tester, (_) async => respostaJson([jsonDeIngresso()]));

      final dados = tester.getCenter(find.text('16/12/2026 às 16:00'));
      final mapa = tester.getCenter(find.byType(MapaRota));
      final botao = tester.getCenter(find.text('VALIDAR INGRESSO'));

      expect(mapa.dx, greaterThan(dados.dx));
      expect(botao.dx, greaterThan(dados.dx));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('em pé, o mapa continua abaixo dos dados', (tester) async {
      configurarAparelho(tester, emPe);
      await abrirInicio(tester, (_) async => respostaJson([jsonDeIngresso()]));

      expect(
        tester.getCenter(find.byType(MapaRota)).dy,
        greaterThan(tester.getCenter(find.text('16/12/2026 às 16:00')).dy),
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a lista continua rolando, com os ingressos em duas colunas', (tester) async {
      configurarAparelho(tester, deitado);
      await abrirInicio(tester, (_) async => respostaJson(ingressosVariados()));

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 300));

      final cartoes = find.byType(CartaoIngresso);
      expect(cartoes, findsNWidgets(3));
      expect(tester.getTopLeft(cartoes.at(0)).dy, tester.getTopLeft(cartoes.at(1)).dy);
      expect(tester.getTopLeft(cartoes.at(1)).dx, greaterThan(tester.getTopLeft(cartoes.at(0)).dx));
      expect(tester.getTopLeft(cartoes.at(2)).dy, greaterThan(tester.getTopLeft(cartoes.at(0)).dy));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('girar não busca os ingressos de novo nem volta ao login', (tester) async {
      configurarAparelho(tester, emPe);
      var chamadas = 0;
      await abrirInicio(tester, (_) async {
        chamadas++;
        return respostaJson([jsonDeIngresso()]);
      });
      expect(chamadas, 1);

      await girar(tester, deitado);
      await tester.pump(const Duration(milliseconds: 100));
      await girar(tester, emPe);
      await tester.pump(const Duration(milliseconds: 100));

      expect(chamadas, 1);
      expect(find.text('VALIDAR INGRESSO'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('QR deitado', () {
    for (final tamanho in const [Size(568, 320), Size(640, 360), Size(844, 390), Size(932, 430)]) {
      testWidgets(
        'em ${tamanho.width.toInt()}x${tamanho.height.toInt()}, fica à esquerda, inteiro e grande',
        (tester) async {
          configurarAparelho(tester, tamanho);
          await abrirQr(tester);

          final qr = tester.getRect(find.byType(QrImageView));
          final dados = tester.getRect(find.text('A01'));

          expect(qr.width, greaterThanOrEqualTo(ladoMinimoDoQr));
          expect(qr.height, greaterThanOrEqualTo(ladoMinimoDoQr));
          expect(qr.right, lessThanOrEqualTo(dados.left));
          expect(qr.bottom, lessThanOrEqualTo(tamanho.height), reason: 'o QR precisa caber sem rolar');
          await tester.pumpWidget(const SizedBox());
        },
      );
    }

    testWidgets('em uma janela larga, como o navegador, o conteúdo não estica', (tester) async {
      configurarAparelho(tester, const Size(1920, 1080));
      await abrirQr(tester);

      final qr = tester.getRect(find.byType(QrImageView));
      expect(qr.width, ladoMaximoDoQr);
      expect(qr.left, greaterThanOrEqualTo((1920 - larguraMaximaDoConteudo) / 2));
      expect(
        tester.getRect(find.text('A01')).right,
        lessThanOrEqualTo(1920 - (1920 - larguraMaximaDoConteudo) / 2),
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('com fonte 2,0, o QR continua inteiro, e só os dados rolam', (tester) async {
      configurarAparelho(tester, const Size(640, 360), escalaDeFonte: 2);
      await abrirQr(tester);

      final antes = tester.getRect(find.byType(QrImageView));
      expect(antes.bottom, lessThanOrEqualTo(360));

      await tester.drag(find.text('Brasil x Sérvia'), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.getRect(find.byType(QrImageView)), antes);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('em pé, o QR continua grande', (tester) async {
      configurarAparelho(tester, const Size(320, 568));
      await abrirQr(tester);

      expect(tester.getSize(find.byType(QrImageView)).width, greaterThanOrEqualTo(ladoMinimoDoQr));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('girar mantém o ingresso aberto e não reinicia a consulta periódica', (tester) async {
      configurarAparelho(tester, emPe);
      const intervalo = Duration(seconds: 5);
      var chamadas = 0;
      final servicos = servicosDeTeste((_) async {
        chamadas++;
        return respostaJson([jsonDeIngresso(utilizado: chamadas >= 3)]);
      }, sessao: sessaoDeTeste());
      await servicos.autenticacao.restaurar();
      await tester.pumpWidget(
        comTema(
          QrTela(
            ingresso: ingressoDeTeste(),
            ingressos: servicos.ingressos,
            relogio: () => agoraFixo,
            intervalo: intervalo,
          ),
        ),
      );

      // Passam 3 segundos, e o aparelho gira. Uma consulta reiniciada só viria 5 segundos depois do giro.
      await tester.pump(const Duration(seconds: 3));
      await girar(tester, deitado);
      expect(chamadas, 0, reason: 'girar não pode disparar uma consulta');
      expect(find.text('Brasil x Sérvia'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 50));
      expect(chamadas, 1, reason: 'a consulta segue o relógio de antes do giro');

      // Girar de novo, e o selo ainda muda quando a Api mudar.
      await girar(tester, emPe);
      await tester.pump(intervalo);
      await tester.pump(const Duration(milliseconds: 50));
      expect(chamadas, 2);
      expect(find.text('VÁLIDO'), findsOneWidget);

      await girar(tester, deitado);
      await tester.pump(intervalo);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400));
      expect(chamadas, 3);
      expect(find.text('UTILIZADO'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Portaria deitada', () {
    Future<void> abrir(WidgetTester tester, Future<http.Response> Function(http.Request) responder) async {
      final servicos = servicosDeTeste(responder, sessao: sessaoDeTeste(perfil: 'ADMIN'));
      await servicos.autenticacao.restaurar();
      await tester.pumpWidget(
        comTema(
          PortariaTela(
            autenticacao: servicos.autenticacao,
            ingressos: servicos.ingressos,
            relogio: () => agoraFixo,
            construirLeitor: (context, aoLer) => const SizedBox.expand(),
          ),
        ),
      );
    }

    Future<void> validar(WidgetTester tester, String codigo) async {
      await tester.enterText(find.byType(TextField), codigo);
      await tester.ensureVisible(find.text('VALIDAR'));
      await tester.pump();
      await tester.tap(find.text('VALIDAR'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('a leitura fica à esquerda, e o histórico à direita', (tester) async {
      configurarAparelho(tester, deitado);
      await abrir(tester, (_) async => respostaJson(jsonLiberado()));

      final botao = tester.getCenter(find.text('LER QR CODE'));
      final historico = tester.getCenter(find.text('Validações desta sessão'));

      expect(historico.dx, greaterThan(botao.dx));
      expect(
        tester.getTopLeft(find.text('Validações desta sessão')).dy,
        greaterThan(tester.getBottomLeft(find.text('ENTRADAS LIBERADAS')).dy),
        reason: 'o contador fica acima do histórico',
      );
      expect(tester.getCenter(find.text('ENTRADAS LIBERADAS')).dx, greaterThan(botao.dx));
    });

    testWidgets('girar mantém o histórico, o contador e o texto do campo', (tester) async {
      configurarAparelho(tester, emPe);
      await abrir(tester, (_) async => respostaJson(jsonLiberado()));

      await validar(tester, 'abc-1');
      await tester.tap(find.text('LER PRÓXIMO'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'meio-digitado');
      await tester.pump();

      await girar(tester, deitado);

      expect(find.text('Brasil x Sérvia'), findsOneWidget);
      expect(find.bySemanticsLabel('Entradas liberadas nesta sessão: 1'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, 'meio-digitado');

      await girar(tester, emPe);
      expect(find.text('Brasil x Sérvia'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, 'meio-digitado');
    });

    testWidgets('girar não tira o foco do campo', (tester) async {
      configurarAparelho(tester, emPe);
      await abrir(tester, (_) async => respostaJson(jsonLiberado()));

      await tester.tap(find.byType(TextField));
      await tester.pump();
      final foco = tester.binding.focusManager.primaryFocus;
      expect(foco, isNotNull);

      await girar(tester, deitado);

      expect(tester.binding.focusManager.primaryFocus, same(foco));
      expect(
        find.descendant(of: find.byType(TextField), matching: find.byType(EditableText)),
        findsOneWidget,
      );
    });

    testWidgets('o resultado fica com o ícone ao lado dos textos', (tester) async {
      configurarAparelho(tester, deitado);
      await abrir(tester, (_) async => respostaJson(jsonLiberado()));

      await validar(tester, 'abc-1');

      expect(
        tester.getCenter(find.text('ENTRADA LIBERADA')).dx,
        greaterThan(tester.getCenter(find.byIcon(Icons.check_circle)).dx),
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('girar no resultado não reinicia a contagem da volta automática', (tester) async {
      configurarAparelho(tester, emPe);
      await abrir(tester, (_) async => respostaJson(jsonLiberado()));

      await validar(tester, 'abc-1');
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Voltando à leitura em 2 s'), findsOneWidget);

      await girar(tester, deitado);
      expect(find.text('ENTRADA LIBERADA'), findsOneWidget);
      expect(find.text('Voltando à leitura em 2 s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('ENTRADA LIBERADA'), findsNothing);
      expect(find.text('LER QR CODE'), findsOneWidget);
    });

    testWidgets('girar com a câmera aberta não remonta o leitor', (tester) async {
      configurarAparelho(tester, emPe);
      var montagens = 0;
      late void Function(String) lerCodigo;
      await tester.pumpWidget(
        comTema(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push<String>(
                MaterialPageRoute(
                  builder: (_) => LeitorQrTela(
                    construirLeitor: (context, aoLer) {
                      lerCodigo = aoLer;
                      return LeitorQueConta(aoMontar: () => montagens++);
                    },
                  ),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(montagens, 1);

      await girar(tester, deitado);
      await tester.pump(const Duration(milliseconds: 100));
      expect(montagens, 1);

      await girar(tester, emPe);
      await tester.pump(const Duration(milliseconds: 100));
      expect(montagens, 1);

      // O leitor continua funcionando depois de girar.
      lerCodigo('abc-1');
      await tester.pumpAndSettle();
      expect(find.byType(LeitorQrTela), findsNothing);
    });
  });

  group('o app inteiro, ao girar', () {
    testWidgets('a sessão continua, e o ADMIN segue na Portaria', (tester) async {
      configurarAparelho(tester, emPe);
      final servicos = servicosDeTeste(
        (_) async => respostaJson(usuarioDeTeste(perfil: 'ADMIN').toJson()),
        sessao: sessaoDeTeste(perfil: 'ADMIN'),
      );
      await tester.pumpWidget(MundialTicketsApp(configuracao: configuracaoDeTeste, servicos: servicos));
      await tester.pump();
      await tester.pump();
      expect(find.byType(PortariaTela), findsOneWidget);
      final estado = tester.state(find.byType(PortariaTela));

      await girar(tester, deitado);

      expect(find.byType(LoginTela), findsNothing);
      expect(tester.state(find.byType(PortariaTela)), same(estado), reason: 'o State não pode ser recriado');
      expect(servicos.autenticacao.sessao.value, isNotNull);
    });

    testWidgets('o CLIENTE segue na tela do torcedor, com o mesmo State', (tester) async {
      configurarAparelho(tester, emPe);
      final servicos = servicosDeTeste((_) async => respostaJson(<Object>[]), sessao: sessaoDeTeste());
      await tester.pumpWidget(MundialTicketsApp(configuracao: configuracaoDeTeste, servicos: servicos));
      await tester.pump();
      await tester.pump();
      final estado = tester.state(find.byType(InicioTela));

      await girar(tester, deitado);

      expect(tester.state(find.byType(InicioTela)), same(estado));
    });

    testWidgets('com o QR aberto por cima, a tela do QR continua aberta', (tester) async {
      configurarAparelho(tester, emPe);
      final completa = Completer<void>();
      final servicos = servicosDeTeste((_) async {
        if (!completa.isCompleted) completa.complete();
        return respostaJson([jsonDeIngresso()]);
      }, sessao: sessaoDeTeste());
      await tester.pumpWidget(MundialTicketsApp(configuracao: configuracaoDeTeste, servicos: servicos));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.ensureVisible(find.text('VALIDAR INGRESSO'));
      await tester.pump();
      await tester.tap(find.text('VALIDAR INGRESSO'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(QrTela), findsOneWidget);
      final estado = tester.state(find.byType(QrTela));

      await girar(tester, deitado);
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.state(find.byType(QrTela)), same(estado));
      expect(find.byType(LoginTela), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
