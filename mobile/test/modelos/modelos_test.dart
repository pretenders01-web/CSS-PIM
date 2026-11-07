import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/modelos/ingresso.dart';
import 'package:mobile/modelos/ingresso_validado.dart';
import 'package:mobile/modelos/sessao.dart';
import 'package:mobile/modelos/usuario.dart';

import '../apoio/falsos.dart';

void main() {
  group('Ingresso.fromJson', () {
    test('lê o JSON completo, com a grafia codigoQR', () {
      final ingresso = Ingresso.fromJson(jsonDeIngresso());

      expect(ingresso.ingressoId, 51);
      expect(ingresso.partida, 'Brasil x Sérvia');
      expect(ingresso.timeA, 'Brasil');
      expect(ingresso.timeB, 'Sérvia');
      expect(ingresso.estadioNome, 'AT&T Stadium');
      expect(ingresso.estadioCidade, 'Dallas');
      expect(ingresso.nomeSetor, 'Arquibancada Inferior');
      expect(ingresso.numeroAssento, 'A01');
      expect(ingresso.codigoQR, 'codigo-51');
      expect(ingresso.utilizado, isFalse);
    });

    test('a data do jogo vem sem fuso e fica com os mesmos dígitos', () {
      final data = Ingresso.fromJson(jsonDeIngresso()).dataJogo;

      expect(data.isUtc, isFalse);
      expect([data.day, data.month, data.year, data.hour, data.minute], [16, 12, 2026, 16, 0]);
    });

    test('aceita assento nulo', () {
      expect(Ingresso.fromJson(jsonDeIngresso(numeroAssento: null)).numeroAssento, isNull);
    });

    test('aceita preço inteiro e com casas decimais', () {
      expect(Ingresso.fromJson({...jsonDeIngresso(), 'precoPago': 450}).precoPago, 450.0);
      expect(Ingresso.fromJson({...jsonDeIngresso(), 'precoPago': 450.00}).precoPago, 450.0);
    });
  });

  group('Sessao', () {
    final json = {
      'token': 'abc',
      'expiraEm': '2026-11-07T06:00:49.8521744Z',
      'usuario': {
        'id': 2,
        'nome': 'Portaria',
        'email': 'p@exemplo.com',
        'cpf': null,
        'dataCadastro': '2026-11-07T01:00:00',
        'ativo': true,
        'perfil': 'ADMIN',
      },
    };

    test('lê o login, com a data em UTC e 7 casas decimais', () {
      final sessao = Sessao.fromJson(json);

      expect(sessao.token, 'abc');
      expect(sessao.expiraEm.isUtc, isTrue);
      expect(sessao.expiraEm.hour, 6);
      expect(sessao.usuario.ehAdmin, isTrue);
      expect(sessao.usuario.cpf, isNull);
    });

    test('toJson e fromJson voltam ao mesmo valor', () {
      final copia = Sessao.fromJson(Sessao.fromJson(json).toJson());

      expect(copia.token, 'abc');
      expect(copia.expiraEm, Sessao.fromJson(json).expiraEm);
      expect(copia.usuario.perfil, 'ADMIN');
    });

    test('o token vence exatamente em expiraEm', () {
      final sessao = Sessao.fromJson(json);

      expect(sessao.expirada(sessao.expiraEm.subtract(const Duration(seconds: 1))), isFalse);
      expect(sessao.expirada(sessao.expiraEm), isTrue);
    });
  });

  test('Usuario: só o perfil ADMIN é administrador', () {
    expect(usuarioDeTeste(perfil: 'ADMIN').ehAdmin, isTrue);
    expect(usuarioDeTeste().ehAdmin, isFalse);
    expect(const Usuario(id: 1, nome: 'a', email: 'b', perfil: 'admin').ehAdmin, isFalse);
  });

  test('IngressoValidado.fromJson aceita assento nulo', () {
    final validado = IngressoValidado.fromJson({
      'ingressoId': 16,
      'partida': 'México x Canadá',
      'dataJogo': '2026-12-14T16:00:00',
      'nomeSetor': 'Arquibancada Superior',
      'numeroAssento': null,
    });

    expect(validado.partida, 'México x Canadá');
    expect(validado.numeroAssento, isNull);
    expect(validado.dataJogo.day, 14);
  });
}
