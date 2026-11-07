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
import '../util/layout.dart';
import '../widgets/bandeira_time.dart';
import '../widgets/cartao_proximo_jogo.dart';
import '../widgets/fundo_cartao_hero.dart';
import '../widgets/selo_ingresso.dart';

/// O lado do QR nunca fica abaixo do mínimo, para a câmera da portaria conseguir ler.
const double ladoMinimoDoQr = 220;
const double ladoMaximoDoQr = 320;

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
    return Scaffold(
      appBar: AppBar(toolbarHeight: alturaDaBarra(context), title: const Text('Ingresso')),
      body: SafeArea(
        // A consulta periódica e o ingresso aberto ficam neste State, acima do layout: girar o
        // aparelho só troca a arrumação da tela, sem reiniciar nada.
        child: LayoutBuilder(
          builder: (context, limites) => estaDeitado(context) ? _emPaisagem(limites) : _emRetrato(limites),
        ),
      ),
    );
  }

  /// Em pé: tudo em uma coluna. O cartão preenche a tela e, com fonte grande, cresce e rola.
  Widget _emRetrato(BoxConstraints limites) {
    const margem = 12.0;
    const interno = 16.0;
    final lado = (limites.maxWidth - (margem + interno) * 2).clamp(ladoMinimoDoQr, ladoMaximoDoQr);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(margem),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: limites.maxHeight - margem * 2),
        child: Stack(
          children: [
            Positioned.fill(child: FundoCartaoHero(ingressoId: _ingresso.ingressoId)),
            Padding(
              padding: const EdgeInsets.all(interno),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _cabecalho(),
                  const SizedBox(height: 16),
                  Center(child: _QuadroDoQr(codigo: _ingresso.codigoQR, lado: lado)),
                  const SizedBox(height: 10),
                  _textoDaSituacao(TextAlign.center),
                  if (_semRede) ...[const SizedBox(height: 8), _avisoSemRede(TextAlign.center)],
                  const SizedBox(height: 16),
                  _dados(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Deitado: o QR à esquerda, com a maior altura disponível, e os dados à direita. Se a fonte for
  /// grande, só os dados rolam, e o QR continua inteiro na tela.
  Widget _emPaisagem(BoxConstraints limites) {
    const margem = 8.0;
    const interno = 12.0;
    final margemDosLados = margemLateral(context, minima: margem);
    final larguraUtil = limites.maxWidth - (margemDosLados + interno) * 2;
    final alturaUtil = limites.maxHeight - (margem + interno) * 2;
    final lado = math.min(alturaUtil, larguraUtil / 2).clamp(ladoMinimoDoQr, ladoMaximoDoQr);

    // Em uma tela baixa demais para o mínimo do QR, a página inteira rola, em vez de encolher o QR.
    final alturaDoCartao = math.max(limites.maxHeight - margem * 2, lado + interno * 2);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: margemDosLados, vertical: margem),
      child: SizedBox(
        height: alturaDoCartao,
        child: Stack(
          children: [
            Positioned.fill(child: FundoCartaoHero(ingressoId: _ingresso.ingressoId)),
            Padding(
              padding: const EdgeInsets.all(interno),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuadroDoQr(codigo: _ingresso.codigoQR, lado: lado),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              BandeiraTime(time: _ingresso.timeA, largura: 36, altura: 24),
                              const SizedBox(width: 6),
                              BandeiraTime(time: _ingresso.timeB, largura: 36, altura: 24),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _ingresso.partida,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Wrap: o que não couber na linha desce para a seguinte, sem estourar.
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [_selo(), _textoDaSituacao(TextAlign.start)],
                          ),
                          if (_semRede) ...[const SizedBox(height: 6), _avisoSemRede(TextAlign.start)],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 20,
                            runSpacing: 8,
                            children: [
                              CampoIngresso(rotulo: 'Setor', valor: _ingresso.nomeSetor),
                              CampoIngresso(rotulo: 'Assento', valor: _ingresso.numeroAssento ?? '—'),
                              CampoIngresso(rotulo: 'Data e hora', valor: formatarDataHora(_ingresso.dataJogo)),
                              CampoIngresso(
                                rotulo: 'Estádio',
                                valor: '${_ingresso.estadioNome}, ${_ingresso.estadioCidade}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _TextoDoCodigo(codigo: _ingresso.codigoQR),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Column(
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
        Center(child: _selo()),
      ],
    );
  }

  Widget _selo() {
    final situacao = _situacao;
    return Semantics(
      liveRegion: true,
      label: 'Situação do ingresso: ${SeloIngresso.textoDe(situacao)}',
      child: ExcludeSemantics(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: SeloIngresso(key: ValueKey(situacao), situacao: situacao, grande: true),
        ),
      ),
    );
  }

  Widget _textoDaSituacao(TextAlign alinhamento) {
    return Text(
      switch (_situacao) {
        SituacaoIngresso.valido => 'Apresente este QR Code na portaria.',
        SituacaoIngresso.utilizado => 'Este ingresso já foi utilizado.',
        SituacaoIngresso.expirado => 'O jogo deste ingresso já começou.',
      },
      textAlign: alinhamento,
      style: const TextStyle(color: Cores.textoSuave),
    );
  }

  Widget _avisoSemRede(TextAlign alinhamento) {
    return Semantics(
      liveRegion: true,
      child: Text(
        'Sem conexão: a situação pode estar desatualizada.',
        textAlign: alinhamento,
        style: const TextStyle(color: Cores.amarelo),
      ),
    );
  }

  Widget _dados() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: CampoIngresso(rotulo: 'Setor', valor: _ingresso.nomeSetor)),
            const SizedBox(width: 12),
            CampoIngresso(rotulo: 'Assento', valor: _ingresso.numeroAssento ?? '—'),
          ],
        ),
        const SizedBox(height: 10),
        CampoIngresso(rotulo: 'Data e hora', valor: formatarDataHora(_ingresso.dataJogo)),
        const SizedBox(height: 10),
        CampoIngresso(rotulo: 'Estádio', valor: '${_ingresso.estadioNome}, ${_ingresso.estadioCidade}'),
        const SizedBox(height: 14),
        _TextoDoCodigo(codigo: _ingresso.codigoQR),
      ],
    );
  }
}

/// O QR fica sobre um quadro branco opaco, com módulos escuros: o vidro escuro do tema
/// atrapalharia a leitura da câmera.
class _QuadroDoQr extends StatelessWidget {
  const _QuadroDoQr({required this.codigo, required this.lado});

  final String codigo;
  final double lado;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
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
          const ExcludeSemantics(
            child: Text(
              'CÓDIGO DO QR',
              style: TextStyle(color: Cores.textoSuave, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 4),
          // Para o leitor de tela, é só um texto: selecionar fica para quem enxerga a tela. Sem isto,
          // o texto selecionável vira um alvo de toque de 19 de altura, abaixo do mínimo de 48.
          Semantics(
            label: 'Código do QR: $codigo',
            child: ExcludeSemantics(
              child: SelectableText(
                codigo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
