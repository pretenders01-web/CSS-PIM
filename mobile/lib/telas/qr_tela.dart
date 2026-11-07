import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../modelos/ingresso.dart';
import '../modelos/situacao_ingresso.dart';
import '../servicos/erros_api.dart';
import '../servicos/ingresso_servico.dart';
import '../tema/cores.dart';
import '../util/formatacao.dart';
import '../widgets/bandeira_time.dart';
import '../widgets/cartao_proximo_jogo.dart';
import '../widgets/fundo_cartao_hero.dart';
import '../widgets/selo_ingresso.dart';

/// O QR Code do ingresso, para mostrar na portaria.
/// Com esta tela aberta, o app consulta a situação a cada poucos segundos, para o selo mudar
/// quando a portaria validar. A consulta para quando a tela fecha.
class QrTela extends StatefulWidget {
  const QrTela({
    super.key,
    required this.ingresso,
    required this.ingressos,
    this.relogio = DateTime.now,
    this.intervalo = const Duration(seconds: 5),
  });

  final Ingresso ingresso;
  final IngressoServico ingressos;

  /// Parâmetros para os testes controlarem a hora e o intervalo.
  final DateTime Function() relogio;
  final Duration intervalo;

  @override
  State<QrTela> createState() => _QrTelaState();
}

class _QrTelaState extends State<QrTela> with WidgetsBindingObserver {
  late Ingresso _ingresso = widget.ingresso;

  Timer? _proximaConsulta;
  bool _consultando = false;
  bool _emPrimeiroPlano = true;
  bool _semRede = false;

  SituacaoIngresso get _situacao => situacaoDoIngresso(_ingresso, widget.relogio());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _agendarConsulta();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _proximaConsulta?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    switch (estado) {
      case AppLifecycleState.resumed:
        _emPrimeiroPlano = true;
        // Pode ter sido validado enquanto o app estava em segundo plano.
        _consultar();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _emPrimeiroPlano = false;
        _proximaConsulta?.cancel();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Um Timer de disparo único, reagendado só depois que a resposta chega: assim uma resposta
  /// lenta nunca se sobrepõe à consulta seguinte. Só consulta enquanto o selo for Válido:
  /// Utilizado e Expirado não mudam mais.
  void _agendarConsulta() {
    _proximaConsulta?.cancel();
    if (!_emPrimeiroPlano || _situacao != SituacaoIngresso.valido) return;
    _proximaConsulta = Timer(widget.intervalo, _consultar);
  }

  Future<void> _consultar() async {
    if (_consultando) return;

    // O jogo pode ter começado com a tela aberta: redesenha, para o selo mudar, e não consulta mais.
    if (_situacao != SituacaoIngresso.valido) {
      if (mounted) setState(() {});
      return;
    }

    _consultando = true;

    try {
      final atual = await widget.ingressos.consultar(_ingresso.ingressoId);
      if (!mounted) return;
      setState(() {
        if (atual != null) _ingresso = atual;
        _semRede = false;
      });
    } on SessaoExpiradaException {
      // O app.dart já está levando de volta ao login.
      return;
    } on SemConexaoException {
      if (!mounted) return;
      // O QR continua na tela: ele não depende da rede.
      setState(() => _semRede = true);
    } on ApiException {
      if (!mounted) return;
      setState(() => _semRede = true);
    } finally {
      _consultando = false;
    }

    _agendarConsulta();
  }

  @override
  Widget build(BuildContext context) {
    final situacao = _situacao;
    final assento = _ingresso.numeroAssento ?? '—';

    return Scaffold(
      appBar: AppBar(title: const Text('Ingresso')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, limites) {
            const margem = 12.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(margem),
              child: ConstrainedBox(
                // O cartão preenche a tela e, com fonte grande, cresce e rola.
                constraints: BoxConstraints(minHeight: limites.maxHeight - margem * 2),
                child: Stack(
                  children: [
                    Positioned.fill(child: FundoCartaoHero(ingressoId: _ingresso.ingressoId)),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              BandeiraTime(time: _ingresso.timeA, largura: 42, altura: 28),
                              const SizedBox(width: 10),
                              BandeiraTime(time: _ingresso.timeB, largura: 42, altura: 28),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _ingresso.partida,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          Semantics(
                            liveRegion: true,
                            label: 'Situação do ingresso: ${SeloIngresso.textoDe(situacao)}',
                            child: ExcludeSemantics(
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: SeloIngresso(
                                    key: ValueKey(situacao),
                                    situacao: situacao,
                                    grande: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _QuadroDoQr(codigo: _ingresso.codigoQR),
                          const SizedBox(height: 10),
                          Text(
                            switch (situacao) {
                              SituacaoIngresso.valido => 'Apresente este QR Code na portaria.',
                              SituacaoIngresso.utilizado => 'Este ingresso já foi utilizado.',
                              SituacaoIngresso.expirado => 'O jogo deste ingresso já começou.',
                            },
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Cores.textoSuave),
                          ),
                          if (_semRede) ...[
                            const SizedBox(height: 8),
                            Semantics(
                              liveRegion: true,
                              child: const Text(
                                'Sem conexão: a situação pode estar desatualizada.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Cores.amarelo),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: CampoIngresso(rotulo: 'Setor', valor: _ingresso.nomeSetor)),
                              const SizedBox(width: 12),
                              CampoIngresso(rotulo: 'Assento', valor: assento),
                            ],
                          ),
                          const SizedBox(height: 10),
                          CampoIngresso(rotulo: 'Data e hora', valor: formatarDataHora(_ingresso.dataJogo)),
                          const SizedBox(height: 10),
                          CampoIngresso(
                            rotulo: 'Estádio',
                            valor: '${_ingresso.estadioNome}, ${_ingresso.estadioCidade}',
                          ),
                          const SizedBox(height: 14),
                          _TextoDoCodigo(codigo: _ingresso.codigoQR),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// O QR fica sobre um quadro branco opaco, com módulos escuros: o vidro escuro do tema
/// atrapalharia a leitura da câmera.
class _QuadroDoQr extends StatelessWidget {
  const _QuadroDoQr({required this.codigo});

  final String codigo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) {
        final lado = math.min(limites.maxWidth, 320.0).clamp(220.0, 320.0);
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: QrImageView(
              data: codigo,
              size: lado,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              backgroundColor: Colors.white,
              // A margem de silêncio: cerca de 4 módulos em volta do desenho.
              padding: EdgeInsets.all(lado * 0.11),
              semanticsLabel: 'QR Code do ingresso',
            ),
          ),
        );
      },
    );
  }
}

/// O texto do código, como na Web. Pode ser selecionado, para digitar ou colar na Portaria.
class _TextoDoCodigo extends StatelessWidget {
  const _TextoDoCodigo({required this.codigo});

  final String codigo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x73000000),
        border: Border.all(color: const Color(0x4DFFFFFF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Text('CÓDIGO DO QR', style: TextStyle(color: Cores.textoSuave, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 4),
          SelectableText(
            codigo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ],
      ),
    );
  }
}
