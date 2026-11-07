import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/telas/login_tela.dart';

import '../apoio/falsos.dart';

Future<void> abrir(WidgetTester tester, Future<http.Response> Function(http.Request) responder) async {
  final servicos = servicosDeTeste(responder);
  await tester.pumpWidget(MaterialApp(home: LoginTela(autenticacao: servicos.autenticacao)));
}

void main() {
  testWidgets('mostra o aviso de que cadastro e compra ficam no site', (tester) async {
    await abrir(tester, (_) async => respostaJson({}));

    expect(find.textContaining('O cadastro e a compra de ingressos são feitos no site'), findsOneWidget);
  });

  testWidgets('campos vazios mostram as mensagens e não chamam a Api', (tester) async {
    var chamadas = 0;
    await abrir(tester, (_) async {
      chamadas++;
      return respostaJson({});
    });

    await tester.tap(find.text('ENTRAR'));
    await tester.pump();

    expect(find.text('Informe o e-mail.'), findsOneWidget);
    expect(find.text('Informe a senha.'), findsOneWidget);
    expect(chamadas, 0);
  });

  testWidgets('e-mail inválido mostra a mensagem', (tester) async {
    await abrir(tester, (_) async => respostaJson({}));

    await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), 'abc');
    await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), 'x');
    await tester.tap(find.text('ENTRAR'));
    await tester.pump();

    expect(find.text('E-mail inválido.'), findsOneWidget);
  });

  testWidgets('o erro da Api aparece na tela', (tester) async {
    await abrir(tester, (_) async => respostaJson({'erro': 'E-mail ou senha incorretos.'}, 401));

    await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), 'ana@exemplo.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), 'errada');
    await tester.tap(find.text('ENTRAR'));
    await tester.pump();
    await tester.pump();

    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
  });

  testWidgets('sem rede, a mensagem é amigável', (tester) async {
    await abrir(tester, (_) async => throw http.ClientException('sem rede'));

    await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), 'ana@exemplo.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), 'x');
    await tester.tap(find.text('ENTRAR'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Não foi possível falar com o servidor'), findsOneWidget);
  });

  testWidgets('a senha fica escondida até o usuário pedir', (tester) async {
    await abrir(tester, (_) async => respostaJson({}));

    TextField campoDaSenha() => tester.widget<TextField>(
      find.descendant(of: find.widgetWithText(TextFormField, 'Senha'), matching: find.byType(TextField)),
    );

    expect(campoDaSenha().obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar a senha'));
    await tester.pump();
    expect(campoDaSenha().obscureText, isFalse);
  });
}
