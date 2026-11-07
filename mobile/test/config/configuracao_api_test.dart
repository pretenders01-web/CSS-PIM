import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/config/configuracao_api.dart';

void main() {
  group('ConfiguracaoApi', () {
    test('endereço vazio mostra como informar', () {
      final configuracao = ConfiguracaoApi.interpretar('   ', release: false);

      expect(configuracao.valida, isFalse);
      expect(configuracao.erro, contains('--dart-define=API_URL'));
    });

    test('endereço http vale em debug e perde a barra final', () {
      final configuracao = ConfiguracaoApi.interpretar('http://exemplo.test:5218/', release: false);

      expect(configuracao.valida, isTrue);
      expect(configuracao.enderecoBase, 'http://exemplo.test:5218');
    });

    test('endereço http é recusado em release', () {
      final configuracao = ConfiguracaoApi.interpretar('http://exemplo.test:5218', release: true);

      expect(configuracao.valida, isFalse);
      expect(configuracao.erro, contains('https://'));
    });

    test('endereço https vale em release', () {
      final configuracao = ConfiguracaoApi.interpretar('https://exemplo.test', release: true);

      expect(configuracao.valida, isTrue);
      expect(configuracao.enderecoBase, 'https://exemplo.test');
    });

    test('endereço sem esquema é inválido', () {
      expect(ConfiguracaoApi.interpretar('exemplo.test:5218', release: false).valida, isFalse);
    });
  });
}
