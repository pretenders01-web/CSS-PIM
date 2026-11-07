import 'package:flutter/material.dart';

import '../modelos/registro_validacao.dart';
import '../tema/cores.dart';
import '../util/formatacao.dart';
import 'cartao_vidro.dart';

/// O contador de entradas liberadas nesta sessão.
class ContadorDeEntradas extends StatelessWidget {
  const ContadorDeEntradas({super.key, required this.liberadas});

  final int liberadas;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Entradas liberadas nesta sessão: $liberadas',
      child: ExcludeSemantics(
        child: CartaoVidro(
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'ENTRADAS LIBERADAS',
                  style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$liberadas',
                style: const TextStyle(color: Cores.amarelo, fontSize: 32, fontWeight: FontWeight.w800, height: 1.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// As validações feitas nesta sessão, da mais recente para a mais antiga.
class HistoricoValidacoes extends StatelessWidget {
  const HistoricoValidacoes({super.key, required this.registros});

  final List<RegistroValidacao> registros;

  @override
  Widget build(BuildContext context) {
    if (registros.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Nenhuma validação ainda.', style: TextStyle(color: Cores.textoSuave)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final registro in registros)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ItemDoHistorico(registro: registro),
          ),
      ],
    );
  }
}

class _ItemDoHistorico extends StatelessWidget {
  const _ItemDoHistorico({required this.registro});

  final RegistroValidacao registro;

  @override
  Widget build(BuildContext context) {
    final hora = formatarHora(registro.horario);
    final partida = registro.partida ?? '—';
    final assento = registro.numeroAssento ?? '—';
    final (textoDoResultado, fundo, borda, corDoTexto) = switch (registro.resultado) {
      ResultadoValidacao.liberada => ('Liberada', Cores.seloVerdeFundo, Cores.verde, Cores.texto),
      ResultadoValidacao.recusada => (
        'Recusada',
        Cores.seloVermelhoFundo,
        Cores.seloVermelhoBorda,
        Cores.seloVermelhoTexto,
      ),
      ResultadoValidacao.naoValidada => ('Não validada', Cores.seloCinzaFundo, Cores.borda, Cores.textoSuave),
    };
    final motivo = registro.resultado == ResultadoValidacao.liberada ? null : registro.motivo;

    return Semantics(
      label:
          '$hora, partida $partida, assento $assento. $textoDoResultado.'
          '${motivo == null ? '' : ' $motivo'}',
      child: ExcludeSemantics(
        child: CartaoVidro(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(hora, style: const TextStyle(color: Cores.textoSuave, fontWeight: FontWeight.w500)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: fundo,
                      border: Border.all(color: borda),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      textoDoResultado.toUpperCase(),
                      style: TextStyle(color: corDoTexto, fontSize: 11.2, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(partida, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('Assento $assento', style: const TextStyle(color: Cores.textoSuave, fontSize: 13)),
              if (motivo != null)
                Text(motivo, style: const TextStyle(color: Cores.textoSuave, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
