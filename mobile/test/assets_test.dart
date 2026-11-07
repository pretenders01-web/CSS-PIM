import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// As 12 bandeiras de Servicos/Bandeiras.cs.
const arquivos = [
  'argentina',
  'brazil',
  'canada',
  'chile',
  'denmark',
  'france',
  'germany',
  'japan',
  'mexico',
  'serbia',
  'uruguay',
  'usa',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bandeiras', () {
    for (final arquivo in arquivos) {
      test('$arquivo carrega e não tem bloco <style>', () async {
        final caminho = 'assets/flags/$arquivo.svg';
        final texto = await rootBundle.loadString(caminho);

        // O flutter_svg ignora <style>. Por isso México, Sérvia e Uruguai foram convertidos
        // com o svgo (passo 2A.3): copiar os originais da Web de novo deixa as cores erradas.
        expect(texto, isNot(contains('<style')));

        final desenho = await vg.loadPicture(SvgStringLoader(texto), null);
        expect(desenho.size.width, greaterThan(0));
        desenho.picture.dispose();
      });
    }
  });

  test('o logo está nos assets', () async {
    final dados = await rootBundle.load('assets/img/logo.png');
    expect(dados.lengthInBytes, greaterThan(0));
  });
}
