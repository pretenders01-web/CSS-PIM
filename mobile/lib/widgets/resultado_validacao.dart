import 'dart:async';

import 'package:flutter/material.dart';

import '../modelos/registro_validacao.dart';
import '../tema/cores.dart';
import '../util/formatacao.dart';
import '../util/layout.dart';

/// O resultado em tela cheia: cor, ícone e texto juntos, para não depender só da cor nem de som.
/// Volta sozinho para a leitura depois de alguns segundos, ou na hora, pelo botão.
class ResultadoValidacaoTela extends StatefulWidget {
  const ResultadoValidacaoTela({
    super.key,
    required this.registro,
    required this.espera,
    required this.aoVoltar,
  });

  final RegistroValidacao registro;
  final Duration espera;
  final VoidCallback aoVoltar;

  @override
  State<ResultadoValidacaoTela> createState() => _ResultadoValidacaoTelaState();
}

class _ResultadoValidacaoTelaState extends State<ResultadoValidacaoTela> {
  late int _segundosRestantes = widget.espera.inSeconds;
  Timer? _contagem;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Com leitor de tela, a volta automática cortaria a leitura do resultado: só o botão volta.
    if (MediaQuery.accessibleNavigationOf(context)) {
      _contagem?.cancel();
      _contagem = null;
    } else {
      _contagem ??= Timer.periodic(const Duration(seconds: 1), (_) => _passarUmSegundo());
    }
  }

  void _passarUmSegundo() {
    if (_segundosRestantes <= 1) {
      _contagem?.cancel();
      widget.aoVoltar();
      return;
    }
    setState(() => _segundosRestantes--);
  }

  @override
  void dispose() {
    _contagem?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registro = widget.registro;

    // Branco sobre o vermelho do site reprova no contraste (3,27). Por isso o texto é escuro (5,94).
    final (fundo, corDoTexto, icone, titulo) = switch (registro.resultado) {
      ResultadoValidacao.liberada => (Cores.verde, Colors.white, Icons.check_circle, 'ENTRADA LIBERADA'),
      ResultadoValidacao.recusada => (Cores.vermelho, Cores.fundo, Icons.cancel, 'ENTRADA RECUSADA'),
      ResultadoValidacao.naoValidada => (Cores.fundo, Colors.white, Icons.wifi_off, 'NÃO VALIDADO'),
    };
    final naoValidada = registro.resultado == ResultadoValidacao.naoValidada;
    final deitado = estaDeitado(context);
    final iconeGrande = Icon(icone, size: deitado ? 80 : 96, color: naoValidada ? Cores.amarelo : corDoTexto);
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: TextStyle(color: corDoTexto, fontSize: deitado ? 26 : 30, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: deitado ? 10 : 20),
        if (registro.resultado == ResultadoValidacao.liberada) ...[
          Text(
            registro.partida ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(color: corDoTexto, fontSize: deitado ? 20 : 24, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: deitado ? 6 : 12),
          Text(
            '${registro.nomeSetor ?? '—'}\n'
            'Assento ${registro.numeroAssento ?? '—'}\n'
            '${registro.dataJogo == null ? '' : formatarDataHora(registro.dataJogo!)}',
            textAlign: TextAlign.center,
            style: TextStyle(color: corDoTexto, fontSize: deitado ? 16 : 18, fontWeight: FontWeight.w600),
          ),
        ] else
          Text(
            registro.motivo ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(color: corDoTexto, fontSize: deitado ? 18 : 20, fontWeight: FontWeight.w600),
          ),
      ],
    );

    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, limites) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: margemLateral(context, minima: deitado ? 16 : 24),
              vertical: deitado ? 16 : 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: limites.maxHeight - (deitado ? 32 : 48)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Deitado: o ícone ao lado dos textos, para caber na altura. A contagem da volta
                  // automática fica neste State, e girar o aparelho não a reinicia.
                  Semantics(
                    liveRegion: true,
                    child: deitado
                        ? Row(
                            children: [
                              iconeGrande,
                              const SizedBox(width: 24),
                              Expanded(child: textos),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [iconeGrande, const SizedBox(height: 16), textos],
                          ),
                  ),
                  SizedBox(height: deitado ? 16 : 32),
                  ElevatedButton(
                    style: naoValidada
                        ? null
                        : ElevatedButton.styleFrom(backgroundColor: Cores.fundo, foregroundColor: Colors.white),
                    onPressed: widget.aoVoltar,
                    child: Text(naoValidada ? 'TENTAR DE NOVO' : 'LER PRÓXIMO'),
                  ),
                  if (_contagem != null) ...[
                    const SizedBox(height: 12),
                    // Fora da leitura de tela: anunciar cada segundo só atrapalharia.
                    ExcludeSemantics(
                      child: Text(
                        'Voltando à leitura em $_segundosRestantes s',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: corDoTexto, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
