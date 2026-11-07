import 'package:flutter/material.dart';

import '../modelos/ingresso.dart';
import '../modelos/situacao_ingresso.dart';
import '../tema/cores.dart';
import '../util/formatacao.dart';
import '../util/layout.dart';
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

/// O cartão da tela inicial: o próximo jogo. Em pé, ocupa cerca de metade da tela, com os dados em
/// cima e o mapa embaixo. Deitado, os dados ficam de um lado e o mapa e os botões do outro.
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
    final deitado = estaDeitado(context);
    final dados = _DadosDoJogo(ingresso: ingresso, compacto: deitado);
    final mapaEBotoes = _MapaEBotoes(
      ingresso: ingresso,
      compacto: deitado,
      alturaDoMapa: (alturaDaTela * (deitado ? 0.22 : 0.12)).clamp(90.0, 130.0),
      aoValidar: aoValidar,
      aoComoChegar: aoComoChegar,
    );

    return ConstrainedBox(
      // Altura MÍNIMA, nunca fixa: com a fonte do sistema grande, o cartão só cresce.
      constraints: BoxConstraints(minHeight: deitado ? 0 : alturaDaTela * 0.5),
      child: Stack(
        children: [
          Positioned.fill(child: FundoCartaoHero(ingressoId: ingresso.ingressoId)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // O topo em degradê, como .ingresso-card .topo-ingresso do site.
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: deitado ? 6 : 10),
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
                padding: EdgeInsets.all(deitado ? 12 : 16),
                child: deitado
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: dados),
                          const SizedBox(width: 16),
                          Expanded(child: mapaEBotoes),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [dados, const SizedBox(height: 14), mapaEBotoes],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DadosDoJogo extends StatelessWidget {
  const _DadosDoJogo({required this.ingresso, required this.compacto});

  final Ingresso ingresso;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final assento = ingresso.numeroAssento ?? '—';
    final quando = formatarDataHora(ingresso.dataJogo);

    return MergeSemantics(
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
                  Expanded(
                    child: _Time(nome: ingresso.timeA, compacto: compacto),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text('x', style: TextStyle(color: Cores.textoSuave, fontSize: 18)),
                  ),
                  Expanded(
                    child: _Time(nome: ingresso.timeB, compacto: compacto),
                  ),
                ],
              ),
              SizedBox(height: compacto ? 10 : 14),
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
              SizedBox(height: compacto ? 6 : 10),
              CampoIngresso(rotulo: 'Data e hora', valor: quando),
              SizedBox(height: compacto ? 6 : 10),
              CampoIngresso(
                rotulo: 'Estádio',
                valor: '${ingresso.estadioNome}, ${ingresso.estadioCidade}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapaEBotoes extends StatelessWidget {
  const _MapaEBotoes({
    required this.ingresso,
    required this.compacto,
    required this.alturaDoMapa,
    required this.aoValidar,
    required this.aoComoChegar,
  });

  final Ingresso ingresso;
  final bool compacto;
  final double alturaDoMapa;
  final VoidCallback aoValidar;
  final VoidCallback aoComoChegar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MapaRota(estadio: ingresso.estadioNome, altura: alturaDoMapa),
        SizedBox(height: compacto ? 10 : 14),
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
    );
  }
}

class _Time extends StatelessWidget {
  const _Time({required this.nome, required this.compacto});

  final String nome;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BandeiraTime(time: nome, largura: compacto ? 48 : 64, altura: compacto ? 32 : 42),
        SizedBox(height: compacto ? 4 : 6),
        Text(
          nome,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ],
    );
  }
}
