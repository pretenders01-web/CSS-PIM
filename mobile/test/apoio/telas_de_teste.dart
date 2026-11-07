import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/telas/inicio_tela.dart';
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
  Future<http.Response> Function(http.Request) responder, {
  String perfil = 'CLIENTE',
}) async {
  final servicos = servicosDeTeste(responder, sessao: sessaoDeTeste(perfil: perfil));
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

/// Abre a Portaria com um leitor falso. Com [respostaDaApi], lê um código e mostra o resultado.
Future<void> abrirPortaria(WidgetTester tester, {http.Response Function()? respostaDaApi}) async {
  final servicos = servicosDeTeste(
    (_) async => respostaDaApi?.call() ?? respostaJson({}),
    sessao: sessaoDeTeste(perfil: 'ADMIN'),
  );
  await servicos.autenticacao.restaurar();
  late void Function(String) lerCodigo;
  await tester.pumpWidget(
    comTema(
      PortariaTela(
        ingressos: servicos.ingressos,
        construirLeitor: (context, aoLer) {
          lerCodigo = aoLer;
          return const SizedBox.expand();
        },
      ),
    ),
  );
  if (respostaDaApi != null) {
    lerCodigo('codigo-51');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }
}

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
