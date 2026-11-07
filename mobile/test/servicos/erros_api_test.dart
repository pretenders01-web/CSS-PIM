import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/servicos/erros_api.dart';

void main() {
  group('mensagemDoErro', () {
    test('usa o campo erro', () {
      expect(mensagemDoErro('{"erro":"E-mail ou senha incorretos."}', 401), 'E-mail ou senha incorretos.');
    });

    test('usa a primeira mensagem de errors', () {
      const corpo = '{"title":"One or more validation errors occurred.","status":400,'
          '"errors":{"Email":["E-mail inválido."],"Senha":["Informe a senha."]}}';

      expect(mensagemDoErro(corpo, 400), 'E-mail inválido.');
    });

    test('corpo vazio no 403 sugere entrar de novo', () {
      expect(mensagemDoErro('', 403), contains('entre de novo'));
    });

    test('HTML no 500 não mostra detalhe técnico', () {
      final mensagem = mensagemDoErro('<html><body>NullReferenceException</body></html>', 500);

      expect(mensagem, contains('servidor'));
      expect(mensagem, isNot(contains('NullReference')));
    });

    test('JSON sem os campos conhecidos usa o texto padrão', () {
      expect(mensagemDoErro('{"title":"Bad Request"}', 400), contains('Não foi possível'));
      expect(mensagemDoErro('[1,2]', 400), contains('Não foi possível'));
    });
  });
}
