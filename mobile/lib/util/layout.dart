import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Celular deitado. A resposta vem do MediaQuery, e não do tamanho que sobra para o widget: o teclado
/// aberto encolhe a área útil, e isso não pode trocar o layout no meio da digitação.
bool estaDeitado(BuildContext context) => MediaQuery.orientationOf(context) == Orientation.landscape;

/// Deitado, a altura é o que falta: a barra superior fica mais baixa, sem perder a área de toque de 48.
double? alturaDaBarra(BuildContext context) => estaDeitado(context) ? 48 : null;

/// Em telas muito largas, como um tablet deitado ou o navegador, o conteúdo não estica além disto.
const double larguraMaximaDoConteudo = 1000;

/// A margem lateral que centraliza o conteúdo nas telas muito largas.
double margemLateral(BuildContext context, {double minima = 16}) =>
    math.max(minima, (MediaQuery.sizeOf(context).width - larguraMaximaDoConteudo) / 2);
