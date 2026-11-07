import 'package:flutter/material.dart';

import '../modelos/situacao_ingresso.dart';
import '../tema/cores.dart';

/// O selo do ingresso, no visual de .selo do site.
/// Sempre traz o texto, para a situação não depender só da cor.
class SeloIngresso extends StatelessWidget {
  const SeloIngresso({super.key, required this.situacao, this.grande = false});

  final SituacaoIngresso situacao;

  /// A tela do QR mostra o selo maior.
  final bool grande;

  static String textoDe(SituacaoIngresso situacao) => switch (situacao) {
    SituacaoIngresso.valido => 'Válido',
    SituacaoIngresso.utilizado => 'Utilizado',
    SituacaoIngresso.expirado => 'Expirado',
  };

  @override
  Widget build(BuildContext context) {
    final (fundo, borda, corDoTexto) = switch (situacao) {
      SituacaoIngresso.valido => (Cores.seloVerdeFundo, Cores.verde, Cores.texto),
      SituacaoIngresso.utilizado => (Cores.seloCinzaFundo, Cores.borda, Cores.textoSuave),
      SituacaoIngresso.expirado => (
        Cores.seloVermelhoFundo,
        Cores.seloVermelhoBorda,
        Cores.seloVermelhoTexto,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: grande ? 16 : 10, vertical: grande ? 6 : 3),
      decoration: BoxDecoration(
        color: fundo,
        border: Border.all(color: borda),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        textoDe(situacao).toUpperCase(),
        style: TextStyle(
          color: corDoTexto,
          fontSize: grande ? 14 : 11.2,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
