import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/mapa_rota.dart';

const mapa = MapaRota(estadio: 'AT&T Stadium');

void main() {
  testWidgets('a animação gera quadros enquanto o mapa está na tela', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: mapa)));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('com outra tela por cima, para de gerar quadros', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: mapa)));
    await tester.pump(const Duration(milliseconds: 100));

    final navegador = tester.state<NavigatorState>(find.byType(Navigator));
    navegador.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('por cima'))));
    await tester.pumpAndSettle();

    expect(find.text('por cima'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);

    // Ao voltar, a animação recomeça.
    navegador.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('longe na lista rolada, o widget é descartado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: 100,
            itemBuilder: (context, indice) => indice == 0 ? mapa : const SizedBox(height: 200),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(MapaRota), findsOneWidget);

    tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(5000);

    // pumpAndSettle só termina quando não há mais quadros: com o mapa animando, daria erro.
    await tester.pumpAndSettle();
    expect(find.byType(MapaRota, skipOffstage: false), findsNothing);
  });

  testWidgets('ao sair da tela, o controller é descartado sem deixar ticker ativo', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: mapa)));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    // Um ticker ativo ao descartar o widget é um erro do Flutter.
    expect(tester.takeException(), isNull);
  });

  testWidgets('com animações reduzidas, não gera quadros', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: Scaffold(body: mapa)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
