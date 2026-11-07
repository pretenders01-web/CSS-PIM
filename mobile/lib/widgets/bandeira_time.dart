import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../tema/cores.dart';
import '../util/bandeiras.dart';

/// A bandeira de um time. Sem bandeira cadastrada, mostra uma bola, como a Web.
/// Fica fora da leitura de tela, como o alt="" da Web: o nome do time está sempre ao lado.
class BandeiraTime extends StatelessWidget {
  const BandeiraTime({super.key, required this.time, this.largura = 28, this.altura = 18});

  final String time;
  final double largura;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final arquivo = arquivoDaBandeira(time);

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        width: largura,
        height: altura,
        child: arquivo != null
            ? SvgPicture.asset(arquivo, fit: BoxFit.cover, excludeFromSemantics: true)
            : ColoredBox(
                color: Cores.seloCinzaFundo,
                child: Center(
                  child: ExcludeSemantics(
                    child: Text('⚽', style: TextStyle(fontSize: altura * 0.6)),
                  ),
                ),
              ),
      ),
    );
  }
}
