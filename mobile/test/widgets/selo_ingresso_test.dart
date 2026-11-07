import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/modelos/situacao_ingresso.dart';
import 'package:mobile/widgets/selo_ingresso.dart';

void main() {
  testWidgets('cada situação mostra o seu texto', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SeloIngresso(situacao: SituacaoIngresso.valido),
              SeloIngresso(situacao: SituacaoIngresso.utilizado),
              SeloIngresso(situacao: SituacaoIngresso.expirado),
            ],
          ),
        ),
      ),
    );

    expect(find.text('VÁLIDO'), findsOneWidget);
    expect(find.text('UTILIZADO'), findsOneWidget);
    expect(find.text('EXPIRADO'), findsOneWidget);
  });
}
