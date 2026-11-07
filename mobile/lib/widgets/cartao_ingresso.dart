import 'package:flutter/material.dart';

import '../modelos/ingresso.dart';
import '../modelos/situacao_ingresso.dart';
import '../tema/cores.dart';
import '../util/formatacao.dart';
import 'bandeira_time.dart';
import 'fundo_cartao_hero.dart';
import 'selo_ingresso.dart';

/// Um item da lista de "outros ingressos". Tocar abre o QR dele.
class CartaoIngresso extends StatelessWidget {
  const CartaoIngresso({super.key, required this.ingresso, required this.situacao, required this.aoTocar});

  final Ingresso ingresso;
  final SituacaoIngresso situacao;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final quando = formatarDataHora(ingresso.dataJogo);
    final assento = ingresso.numeroAssento ?? '—';

    return Semantics(
      button: true,
      label:
          '${ingresso.partida}, $quando. Setor ${ingresso.nomeSetor}, assento $assento. '
          '${SeloIngresso.textoDe(situacao)}. Abrir o QR Code.',
      child: ExcludeSemantics(
        child: Stack(
          children: [
            Positioned.fill(child: FundoCartaoHero(ingressoId: ingresso.ingressoId)),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: aoTocar,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          BandeiraTime(time: ingresso.timeA),
                          const SizedBox(width: 6),
                          BandeiraTime(time: ingresso.timeB),
                          const Spacer(),
                          SeloIngresso(situacao: situacao),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(ingresso.partida, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(quando, style: const TextStyle(color: Cores.textoSuave, fontSize: 13)),
                      Text(
                        '${ingresso.nomeSetor} · Assento $assento',
                        style: const TextStyle(color: Cores.textoSuave, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
