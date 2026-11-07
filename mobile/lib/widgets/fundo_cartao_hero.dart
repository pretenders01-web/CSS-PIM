import 'package:flutter/material.dart';

import '../tema/cores.dart';
import 'cartao_vidro.dart';

/// A etiqueta do Hero precisa ser única por ingresso.
String etiquetaDoIngresso(int ingressoId) => 'ingresso-$ingressoId';

/// O fundo de vidro do cartão, que voa da tela inicial até a tela do QR.
///
/// O Hero envolve só o fundo, e não o conteúdo: texto dentro de um Hero tende a estourar o layout
/// durante o voo. O voo começa opaco, para cobrir o conteúdo que fica para trás, e termina
/// transparente, para mostrar o conteúdo da tela nova.
class FundoCartaoHero extends StatelessWidget {
  const FundoCartaoHero({super.key, required this.ingressoId});

  final int ingressoId;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: etiquetaDoIngresso(ingressoId),
      flightShuttleBuilder: (context, animacao, direcao, origem, destino) => AnimatedBuilder(
        animation: animacao,
        builder: (context, _) => DecoratedBox(
          decoration: decoracaoDeVidro(cor: Color.lerp(Cores.painelOpaco, Cores.painel, animacao.value)!),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: DecoratedBox(decoration: decoracaoDeVidro()),
      ),
    );
  }
}

/// A rota que abre o QR: um fade curto, para o cartão ser o destaque da transição.
Route<T> rotaDoCartao<T>(WidgetBuilder construir) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 450),
  reverseTransitionDuration: const Duration(milliseconds: 350),
  pageBuilder: (context, animacao, animacaoSecundaria) => construir(context),
  transitionsBuilder: (context, animacao, animacaoSecundaria, tela) =>
      FadeTransition(opacity: animacao, child: tela),
);
