import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/config/configuracao_api.dart';
import 'package:mobile/telas/configuracao_ausente_tela.dart';
import 'package:mobile/telas/inicio_tela.dart';
import 'package:mobile/telas/login_tela.dart';

import 'apoio/falsos.dart';

void main() {
  testWidgets('sem o endereço da Api, o app explica como informar', (tester) async {
    await tester.pumpWidget(
      MundialTicketsApp(configuracao: ConfiguracaoApi.interpretar('', release: false)),
    );

    expect(find.byType(ConfiguracaoAusenteTela), findsOneWidget);
    expect(find.textContaining('--dart-define=API_URL'), findsOneWidget);
  });

  testWidgets('sem sessão guardada, abre o login', (tester) async {
    final servicos = servicosDeTeste((_) async => respostaJson({}));

    await tester.pumpWidget(MundialTicketsApp(configuracao: configuracaoDeTeste, servicos: servicos));
    await tester.pump();
    await tester.pump();

    expect(find.byType(LoginTela), findsOneWidget);
  });

  testWidgets('com sessão guardada, abre a tela inicial', (tester) async {
    final servicos = servicosDeTeste((_) async => respostaJson(<Object>[]), sessao: sessaoDeTeste());

    await tester.pumpWidget(MundialTicketsApp(configuracao: configuracaoDeTeste, servicos: servicos));
    await tester.pump();
    await tester.pump();

    expect(find.byType(InicioTela), findsOneWidget);
  });

  testWidgets('o 401 de uma chamada leva de volta ao login, com o aviso', (tester) async {
    final servicos = servicosDeTeste((_) async => respostaJson({}, 401), sessao: sessaoDeTeste());

    await tester.pumpWidget(MundialTicketsApp(configuracao: configuracaoDeTeste, servicos: servicos));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byType(LoginTela), findsOneWidget);
    expect(find.text('Sua sessão expirou. Entre de novo.'), findsOneWidget);
  });

  testWidgets('o app usa o tema escuro do site', (tester) async {
    final servicos = servicosDeTeste((_) async => respostaJson({}));

    await tester.pumpWidget(MundialTicketsApp(configuracao: configuracaoDeTeste, servicos: servicos));
    await tester.pump();

    final tema = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
    expect(tema.scaffoldBackgroundColor, const Color(0xFF0D0D0D));
  });
}
