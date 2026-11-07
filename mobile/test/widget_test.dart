import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/config/configuracao_api.dart';
import 'package:mobile/telas/configuracao_ausente_tela.dart';

void main() {
  testWidgets('sem o endereço da Api, o app explica como informar', (tester) async {
    await tester.pumpWidget(
      MundialTicketsApp(configuracao: ConfiguracaoApi.interpretar('', release: false)),
    );

    expect(find.byType(ConfiguracaoAusenteTela), findsOneWidget);
    expect(find.textContaining('--dart-define=API_URL'), findsOneWidget);
  });
}
