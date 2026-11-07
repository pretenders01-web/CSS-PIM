import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../tema/cores.dart';

/// Mapinha ilustrado: uma rota se desenha até uma bandeira. Não é um mapa real e não usa chave de API.
///
/// A animação fica parada fora da tela, sem nenhum pacote a mais:
///   - com outra tela por cima, o Overlay desliga o ticker do controller;
///   - com o app em segundo plano, o Flutter não gera quadros;
///   - com o cartão longe na lista rolada, a lista descarta o widget, e o dispose encerra o controller.
class MapaRota extends StatefulWidget {
  const MapaRota({super.key, required this.estadio, this.altura = 120});

  final String estadio;
  final double altura;

  @override
  State<MapaRota> createState() => _MapaRotaState();
}

class _MapaRotaState extends State<MapaRota> with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Quem pediu ao sistema para reduzir animações vê o desenho pronto.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controlador.stop();
      _controlador.value = 1;
    } else if (!_controlador.isAnimating) {
      _controlador.repeat();
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Mapa ilustrativo da rota até o ${widget.estadio}',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: widget.altura,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // O RepaintBoundary e o "repaint" fazem cada quadro redesenhar só o mapa,
                // sem reconstruir os widgets do cartão.
                RepaintBoundary(child: CustomPaint(painter: PintorDaRota(_controlador))),
                const Positioned(
                  left: 8,
                  bottom: 4,
                  child: Text('Mapa ilustrativo', style: TextStyle(color: Cores.textoSuave, fontSize: 10)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PintorDaRota extends CustomPainter {
  PintorDaRota(this.animacao) : super(repaint: animacao);

  final Animation<double> animacao;

  // A rota desenha nos primeiros 70% do ciclo, e o resto é a pausa com a bandeira.
  static const double _fimDoDesenho = 0.7;

  Size? _tamanhoCalculado;
  late PathMetric _trajeto;

  @override
  void paint(Canvas canvas, Size size) {
    _desenharFundo(canvas, size);

    if (_tamanhoCalculado != size) {
      _trajeto = _criarRota(size).computeMetrics().first;
      _tamanhoCalculado = size;
    }

    final ciclo = animacao.value;
    final desenhado = Curves.easeInOut.transform(math.min(ciclo / _fimDoDesenho, 1));
    final chegou = desenhado >= 1;

    // A rota inteira, bem clara, e por cima o trecho já percorrido.
    canvas.drawPath(
      _trajeto.extractPath(0, _trajeto.length),
      Paint()
        ..color = const Color(0x24FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      _trajeto.extractPath(0, _trajeto.length * desenhado),
      Paint()
        ..color = Cores.amarelo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    final origem = _trajeto.getTangentForOffset(0)!.position;
    canvas.drawCircle(origem, 5, Paint()..color = Cores.verdeForte);
    canvas.drawCircle(
      origem,
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final destino = _trajeto.getTangentForOffset(_trajeto.length)!.position;
    if (chegou) {
      // Uma onda que se abre em volta do destino quando a rota chega.
      final onda = ((ciclo - _fimDoDesenho) / (1 - _fimDoDesenho)).clamp(0.0, 1.0);
      canvas.drawCircle(
        destino,
        6 + 14 * onda,
        Paint()
          ..color = Cores.amarelo.withValues(alpha: 0.45 * (1 - onda))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    } else {
      final ponta = _trajeto.getTangentForOffset(_trajeto.length * desenhado)!.position;
      canvas.drawCircle(ponta, 4, Paint()..color = Colors.white);
    }

    _desenharBandeira(canvas, destino, size.height, destacada: chegou);
  }

  void _desenharFundo(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF141414));

    // Quarteirões e ruas, só para sugerir um mapa.
    final rua = Paint()
      ..color = const Color(0x12FFFFFF)
      ..strokeWidth = 6;
    final ruaFina = Paint()
      ..color = const Color(0x0DFFFFFF)
      ..strokeWidth = 3;

    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.18), rua);
    canvas.drawLine(Offset(0, size.height * 0.72), Offset(size.width, size.height * 0.84), rua);
    canvas.drawLine(Offset(size.width * 0.22, 0), Offset(size.width * 0.3, size.height), rua);
    canvas.drawLine(Offset(size.width * 0.68, 0), Offset(size.width * 0.6, size.height), rua);

    for (final fator in const [0.1, 0.45, 0.82, 0.92]) {
      canvas.drawLine(
        Offset(size.width * fator, 0),
        Offset(size.width * (fator + 0.04), size.height),
        ruaFina,
      );
    }
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.55), ruaFina);
  }

  Path _criarRota(Size size) {
    final l = size.width;
    final a = size.height;
    return Path()
      ..moveTo(l * 0.08, a * 0.78)
      ..cubicTo(l * 0.24, a * 1.02, l * 0.34, a * 0.34, l * 0.52, a * 0.52)
      ..cubicTo(l * 0.66, a * 0.66, l * 0.72, a * 0.72, l * 0.88, a * 0.46);
  }

  void _desenharBandeira(Canvas canvas, Offset base, double alturaDoMapa, {required bool destacada}) {
    final alturaDoMastro = math.min(alturaDoMapa * 0.34, 34.0);
    final topo = base.translate(0, -alturaDoMastro);
    final opacidade = destacada ? 1.0 : 0.45;

    canvas.drawLine(
      base,
      topo,
      Paint()
        ..color = Colors.white.withValues(alpha: opacidade)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    final pano = Path()
      ..moveTo(topo.dx, topo.dy)
      ..lineTo(topo.dx + alturaDoMastro * 0.62, topo.dy + alturaDoMastro * 0.24)
      ..lineTo(topo.dx, topo.dy + alturaDoMastro * 0.48)
      ..close();
    canvas.drawPath(pano, Paint()..color = Cores.amarelo.withValues(alpha: opacidade));
  }

  @override
  bool shouldRepaint(PintorDaRota oldDelegate) => oldDelegate.animacao != animacao;
}
