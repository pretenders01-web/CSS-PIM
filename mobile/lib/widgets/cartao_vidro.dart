import 'package:flutter/material.dart';

import '../tema/cores.dart';

/// A decoração de .cartao-vidro do site: branco a 5%, borda branca a 8% e cantos arredondados.
/// Sem o desfoque do site: sobre fundo liso ele não muda a imagem e custa caro em um cartão animado.
BoxDecoration decoracaoDeVidro({Color cor = Cores.painel}) => BoxDecoration(
  color: cor,
  border: Border.all(color: Cores.borda),
  borderRadius: BorderRadius.circular(18),
  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, 4))],
);

class CartaoVidro extends StatelessWidget {
  const CartaoVidro({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: decoracaoDeVidro(),
      child: child,
    );
  }
}
