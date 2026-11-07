import 'package:flutter/material.dart';

/// As cores do site (backend/MundialTickets.Web/wwwroot/css/mundial.css), em um só lugar.
abstract final class Cores {
  static const Color fundo = Color(0xFF0D0D0D);
  static const Color verde = Color(0xFF277234);

  /// É o hover do site. Serve para texto verde sobre o fundo, porque tem contraste 5,16,
  /// enquanto o verde normal tem 3,28 e só serve para texto grande e ícones.
  static const Color verdeForte = Color(0xFF329643);
  static const Color amarelo = Color(0xFFFFCC29);
  static const Color vermelho = Color(0xFFFF4D4D);

  static const Color texto = Colors.white;

  /// Branco a 70%.
  static const Color textoSuave = Color(0xB3FFFFFF);

  /// Fundo e borda dos cartões de vidro: branco a 5% e a 8%.
  static const Color painel = Color(0x0DFFFFFF);
  static const Color borda = Color(0x14FFFFFF);

  /// O mesmo tom do painel sobre o fundo, só que opaco. O Hero usa no começo do voo.
  static const Color painelOpaco = Color(0xFF191919);

  // Selos: .selo-verde, .selo-cinza e .selo-vermelho.
  static const Color seloVerdeFundo = Color(0x4D277234);
  static const Color seloCinzaFundo = Color(0x14FFFFFF);
  static const Color seloVermelhoFundo = Color(0x26FF4D4D);
  static const Color seloVermelhoBorda = Color(0x80FF4D4D);
  static const Color seloVermelhoTexto = Color(0xFFFF9A9A);
}
