import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/bandeira_time.dart';

void main() {
  testWidgets('time conhecido usa a bandeira', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BandeiraTime(time: 'Brasil')));

    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('time desconhecido mostra a bola, como a Web', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BandeiraTime(time: 'Atlantis')));

    expect(find.byType(SvgPicture), findsNothing);
    expect(find.text('⚽'), findsOneWidget);
  });
}
