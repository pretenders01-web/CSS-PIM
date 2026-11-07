import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/modelos/situacao_ingresso.dart';

import '../apoio/falsos.dart';

void main() {
  final agora = DateTime(2026, 12, 15, 12);

  group('situacaoDoIngresso', () {
    test('não utilizado com jogo no futuro é Válido', () {
      expect(situacaoDoIngresso(ingressoDeTeste(), agora), SituacaoIngresso.valido);
    });

    test('não utilizado com jogo no passado é Expirado', () {
      final ingresso = ingressoDeTeste(dataJogo: '2026-12-14T16:00:00');

      expect(situacaoDoIngresso(ingresso, agora), SituacaoIngresso.expirado);
    });

    test('no instante do início do jogo já é Expirado, sem tolerância', () {
      final ingresso = ingressoDeTeste(dataJogo: '2026-12-15T12:00:00');

      expect(situacaoDoIngresso(ingresso, agora), SituacaoIngresso.expirado);
    });

    test('utilizado continua Utilizado depois de o jogo passar', () {
      final ingresso = ingressoDeTeste(dataJogo: '2026-12-14T16:00:00', utilizado: true);

      expect(situacaoDoIngresso(ingresso, agora), SituacaoIngresso.utilizado);
    });
  });

  group('separarIngressos', () {
    test('lista vazia', () {
      final r = separarIngressos([], agora);

      expect(r.proximo, isNull);
      expect(r.outros, isEmpty);
    });

    test('tudo usado: sem próximo jogo, e todos ficam em outros', () {
      final lista = [ingressoDeTeste(ingressoId: 1, utilizado: true), ingressoDeTeste(ingressoId: 2, utilizado: true)];
      final r = separarIngressos(lista, agora);

      expect(r.proximo, isNull);
      expect(r.outros, hasLength(2));
    });

    test('tudo passado: sem próximo jogo', () {
      final r = separarIngressos([ingressoDeTeste(dataJogo: '2026-12-01T16:00:00')], agora);

      expect(r.proximo, isNull);
      expect(r.outros, hasLength(1));
    });

    test('escolhe o válido com o jogo mais próximo, mesmo fora de ordem', () {
      final longe = ingressoDeTeste(ingressoId: 1, dataJogo: '2026-12-19T16:00:00');
      final perto = ingressoDeTeste(ingressoId: 2, dataJogo: '2026-12-16T16:00:00');
      final usado = ingressoDeTeste(ingressoId: 3, dataJogo: '2026-12-15T16:00:00', utilizado: true);
      final r = separarIngressos([longe, perto, usado], agora);

      expect(r.proximo, same(perto));
      expect(r.outros, [longe, usado]);
    });

    test('jogo que começou deixa de ser o próximo', () {
      final emAndamento = ingressoDeTeste(ingressoId: 1, dataJogo: '2026-12-15T11:00:00');
      final seguinte = ingressoDeTeste(ingressoId: 2, dataJogo: '2026-12-16T16:00:00');

      expect(separarIngressos([emAndamento, seguinte], agora).proximo, same(seguinte));
    });

    test('dois ingressos do mesmo jogo: fica o de menor id, e o outro vai para a lista', () {
      final maior = ingressoDeTeste(ingressoId: 9);
      final menor = ingressoDeTeste(ingressoId: 4);
      final r = separarIngressos([maior, menor], agora);

      expect(r.proximo, same(menor));
      expect(r.outros, [maior]);
    });
  });
}
