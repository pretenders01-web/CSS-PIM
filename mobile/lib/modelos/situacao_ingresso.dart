import 'ingresso.dart';

/// O que o selo do ingresso mostra.
/// Expirado só existe no app: ingresso não utilizado cujo jogo já começou.
enum SituacaoIngresso { valido, utilizado, expirado }

/// Decide pela data atual do jogo, a mesma que a Api confere na portaria.
/// Um ingresso usado continua Utilizado, mesmo depois de o jogo passar.
SituacaoIngresso situacaoDoIngresso(Ingresso ingresso, DateTime agora) {
  if (ingresso.utilizado) return SituacaoIngresso.utilizado;
  if (!ingresso.dataJogo.isAfter(agora)) return SituacaoIngresso.expirado;
  return SituacaoIngresso.valido;
}

/// Separa o ingresso do cartão (o válido com o jogo mais próximo) dos demais, que mantêm a ordem da Api.
({Ingresso? proximo, List<Ingresso> outros}) separarIngressos(List<Ingresso> lista, DateTime agora) {
  Ingresso? proximo;
  for (final ingresso in lista) {
    if (situacaoDoIngresso(ingresso, agora) != SituacaoIngresso.valido) continue;

    final maisCedo = proximo == null || ingresso.dataJogo.isBefore(proximo.dataJogo);
    final empate =
        proximo != null &&
        ingresso.dataJogo.isAtSameMomentAs(proximo.dataJogo) &&
        ingresso.ingressoId < proximo.ingressoId;
    if (maisCedo || empate) proximo = ingresso;
  }

  return (
    proximo: proximo,
    outros: [
      for (final ingresso in lista)
        if (!identical(ingresso, proximo)) ingresso,
    ],
  );
}
