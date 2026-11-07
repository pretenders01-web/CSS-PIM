import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/telas/inicio_tela.dart';
import 'package:mobile/telas/leitor_qr_tela.dart';
import 'package:mobile/telas/login_tela.dart';
import 'package:mobile/telas/portaria_tela.dart';
import 'package:mobile/telas/qr_tela.dart';
import 'package:mobile/tema/tema_app.dart';

import 'falsos.dart';

/// Carrega a Poppins de verdade, para os testes medirem o texto como no aparelho.
Future<void> carregarPoppins() async {
  final fonte = FontLoader('Poppins');
  for (final peso in const ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    fonte.addFont(rootBundle.load('assets/fonts/Poppins-$peso.ttf'));
  }
  await fonte.load();
}

/// Ajusta o tamanho da tela e a escala de fonte do sistema até o fim do teste.
void configurarAparelho(WidgetTester tester, Size tamanho, {double escalaDeFonte = 1, double densidade = 1}) {
  tester.view.devicePixelRatio = densidade;
  tester.view.physicalSize = tamanho * densidade;
  tester.platformDispatcher.textScaleFactorTestValue = escalaDeFonte;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

Widget comTema(Widget tela) => MaterialApp(theme: criarTemaApp(), home: tela);

final agoraFixo = DateTime(2026, 12, 10, 12);

/// Um pouco de tudo: o próximo jogo e os três selos na lista.
List<Map<String, dynamic>> ingressosVariados() => [
  jsonDeIngresso(ingressoId: 1, timeA: 'Estados Unidos', timeB: 'Uruguai', dataJogo: '2026-12-15T16:00:00'),
  jsonDeIngresso(ingressoId: 2, timeA: 'México', timeB: 'Canadá', dataJogo: '2026-12-14T16:00:00', utilizado: true),
  jsonDeIngresso(ingressoId: 3, timeA: 'Argentina', timeB: 'Dinamarca', dataJogo: '2026-12-01T16:00:00'),
  jsonDeIngresso(ingressoId: 4, timeA: 'Alemanha', timeB: 'Japão', dataJogo: '2026-12-19T16:00:00'),
];

Future<void> abrirLogin(WidgetTester tester, {bool comErros = false}) async {
  final servicos = servicosDeTeste((_) async => respostaJson({}));
  await tester.pumpWidget(comTema(LoginTela(autenticacao: servicos.autenticacao)));
  if (comErros) {
    await tester.tap(find.text('ENTRAR'));
    await tester.pump();
  }
}

Future<void> abrirInicio(
  WidgetTester tester,
  Future<http.Response> Function(http.Request) responder,
) async {
  final servicos = servicosDeTeste(responder, sessao: sessaoDeTeste());
  await servicos.autenticacao.restaurar();
  await tester.pumpWidget(
    comTema(
      InicioTela(
        autenticacao: servicos.autenticacao,
        ingressos: servicos.ingressos,
        relogio: () => agoraFixo,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> abrirQr(WidgetTester tester, {bool utilizado = false, String dataJogo = '2026-12-16T16:00:00'}) async {
  final servicos = servicosDeTeste((_) async => respostaJson(<Object>[]), sessao: sessaoDeTeste());
  await servicos.autenticacao.restaurar();
  await tester.pumpWidget(
    comTema(
      QrTela(
        ingresso: ingressoDeTeste(utilizado: utilizado, dataJogo: dataJogo),
        ingressos: servicos.ingressos,
        relogio: () => agoraFixo,
      ),
    ),
  );
}

/// Abre a Portaria com um leitor falso. Com [respostaDaApi], valida um código e mostra o resultado.
/// Com [voltarParaALeitura], fecha o resultado, para mostrar o contador e o histórico.
Future<void> abrirPortaria(
  WidgetTester tester, {
  http.Response Function()? respostaDaApi,
  bool voltarParaALeitura = false,
}) async {
  final servicos = servicosDeTeste(
    (_) async => respostaDaApi?.call() ?? respostaJson({}),
    sessao: sessaoDeTeste(perfil: 'ADMIN'),
  );
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
  if (respostaDaApi != null) {
    await tester.enterText(find.byType(TextField), 'codigo-51');
    await tester.ensureVisible(find.text('VALIDAR'));
    await tester.pump();
    await tester.tap(find.text('VALIDAR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }
  if (voltarParaALeitura) {
    await tester.ensureVisible(find.text('LER PRÓXIMO'));
    await tester.pump();
    await tester.tap(find.text('LER PRÓXIMO'));
    await tester.pump();
  }
}

/// A tela da câmera, com um leitor falso.
Future<void> abrirCameraDaPortaria(WidgetTester tester) => tester.pumpWidget(
  comTema(LeitorQrTela(construirLeitor: (context, aoLer) => const SizedBox.expand())),
);

http.Response respostaLiberada() => respostaJson({
  'ingressoId': 1,
  'partida': 'Estados Unidos x Uruguai',
  'dataJogo': '2026-12-15T16:00:00',
  'nomeSetor': 'Arquibancada Superior',
  'numeroAssento': 'B10',
});

http.Response respostaRecusada() =>
    respostaJson({'erro': 'Código não encontrado: este QR não pertence a nenhum ingresso.'}, 400);

http.Response respostaSemPermissao() => http.Response('', 403);
