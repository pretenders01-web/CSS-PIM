import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/util/bandeiras.dart';
import 'package:mobile/util/como_chegar.dart';
import 'package:mobile/util/formatacao.dart';
import 'package:mobile/util/validadores.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('arquivoDaBandeira', () {
    const esperados = {
      'México': 'mexico',
      'Canadá': 'canada',
      'Estados Unidos': 'usa',
      'Uruguai': 'uruguay',
      'Brasil': 'brazil',
      'Sérvia': 'serbia',
      'Argentina': 'argentina',
      'Dinamarca': 'denmark',
      'França': 'france',
      'Chile': 'chile',
      'Alemanha': 'germany',
      'Japão': 'japan',
      'EUA': 'usa',
    };

    esperados.forEach((time, arquivo) {
      test('$time usa $arquivo, e o arquivo existe', () async {
        final caminho = arquivoDaBandeira(time);

        expect(caminho, 'assets/flags/$arquivo.svg');
        expect((await rootBundle.load(caminho!)).lengthInBytes, greaterThan(0));
      });
    });

    test('ignora espaços e maiúsculas', () {
      expect(arquivoDaBandeira('  BRASIL '), 'assets/flags/brazil.svg');
    });

    test('time desconhecido ou nulo não tem bandeira', () {
      expect(arquivoDaBandeira('Atlantis'), isNull);
      expect(arquivoDaBandeira(null), isNull);
    });
  });

  group('enderecoDoMapa', () {
    test('o & de "AT&T Stadium" não quebra o endereço', () {
      final endereco = enderecoDoMapa('AT&T Stadium', 'Dallas');

      expect(endereco.toString(), contains('AT%26T'));
      expect(endereco.queryParameters['query'], 'AT&T Stadium, Dallas');
      expect(endereco.queryParameters['api'], '1');
      expect(endereco.host, 'www.google.com');
    });

    test('acentos e espaços vão codificados', () {
      final endereco = enderecoDoMapa('Estádio Azteca', 'Cidade do México');

      expect(endereco.queryParameters['query'], 'Estádio Azteca, Cidade do México');
      expect(endereco.toString(), isNot(contains(' ')));
    });
  });

  test('formatarDataHora usa o formato do site', () {
    expect(formatarDataHora(DateTime(2026, 12, 6, 9, 5)), '06/12/2026 às 09:05');
  });

  group('validadores do login', () {
    test('e-mail', () {
      expect(validarEmail(''), 'Informe o e-mail.');
      expect(validarEmail('  '), 'Informe o e-mail.');
      expect(validarEmail('abc'), 'E-mail inválido.');
      expect(validarEmail('@exemplo.com'), 'E-mail inválido.');
      expect(validarEmail('ana@'), 'E-mail inválido.');
      expect(validarEmail('a@b@c'), 'E-mail inválido.');
      expect(validarEmail(' ana@exemplo.com '), isNull);
    });

    test('senha', () {
      expect(validarSenha(''), 'Informe a senha.');
      expect(validarSenha('x'), isNull);
    });
  });
}
