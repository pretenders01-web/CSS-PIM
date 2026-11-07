import 'package:flutter/material.dart';

import '../modelos/ingresso.dart';
import '../modelos/situacao_ingresso.dart';
import '../tema/cores.dart';
import '../util/formatacao.dart';
import 'bandeira_time.dart';
import 'fundo_cartao_hero.dart';
import 'mapa_rota.dart';
import 'selo_ingresso.dart';

/// Um rótulo pequeno com o valor embaixo, como .ingresso-card .campo do site.
class CampoIngresso extends StatelessWidget {
  const CampoIngresso({super.key, required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo.toUpperCase(),
          style: const TextStyle(color: Cores.textoSuave, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1),
        ),
        Text(valor, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

/// O cartão da tela inicial: o próximo jogo, com cerca de metade da tela.
class CartaoProximoJogo extends StatelessWidget {
  const CartaoProximoJogo({
    super.key,
    required this.ingresso,
    required this.aoValidar,
    required this.aoComoChegar,
  });

  final Ingresso ingresso;
  final VoidCallback aoValidar;
  final VoidCallback aoComoChegar;

  @override
  Widget build(BuildContext context) {
    final alturaDaTela = MediaQuery.sizeOf(context).height;
    final assento = ingresso.numeroAssento ?? '—';
    final quando = formatarDataHora(ingresso.dataJogo);

    return ConstrainedBox(
      // Altura MÍNIMA, nunca fixa: com a fonte do sistema grande, o cartão só cresce.
      constraints: BoxConstraints(minHeight: alturaDaTela * 0.5),
      child: Stack(
        children: [
          Positioned.fill(child: FundoCartaoHero(ingressoId: ingresso.ingressoId)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // O topo em degradê, como .ingresso-card .topo-ingresso do site.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Cores.verde, Color(0xFF1C5427)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'PRÓXIMO JOGO',
                        style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                    ),
                    SeloIngresso(situacao: SituacaoIngresso.valido),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MergeSemantics(
                      child: Semantics(
                        label:
                            'Próximo jogo: ${ingresso.partida}, $quando, ${ingresso.estadioNome}, '
                            '${ingresso.estadioCidade}. Setor ${ingresso.nomeSetor}, assento $assento.',
                        child: ExcludeSemantics(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _Time(nome: ingresso.timeA)),
                                  const Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Text('x', style: TextStyle(color: Cores.textoSuave, fontSize: 18)),
                                  ),
                                  Expanded(child: _Time(nome: ingresso.timeB)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: CampoIngresso(rotulo: 'Setor', valor: ingresso.nomeSetor),
                                  ),
                                  const SizedBox(width: 12),
                                  CampoIngresso(rotulo: 'Assento', valor: assento),
                                ],
                              ),
                              const SizedBox(height: 10),
                              CampoIngresso(rotulo: 'Data e hora', valor: quando),
                              const SizedBox(height: 10),
                              CampoIngresso(
                                rotulo: 'Estádio',
                                valor: '${ingresso.estadioNome}, ${ingresso.estadioCidade}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    MapaRota(estadio: ingresso.estadioNome, altura: (alturaDaTela * 0.12).clamp(90.0, 130.0)),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: aoValidar,
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('VALIDAR INGRESSO'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: aoComoChegar,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('COMO CHEGAR'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Time extends StatelessWidget {
  const _Time({required this.nome});

  final String nome;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BandeiraTime(time: nome, largura: 64, altura: 42),
        const SizedBox(height: 6),
        Text(
          nome,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ],
    );
  }
}
