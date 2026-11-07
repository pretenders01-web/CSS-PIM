import 'package:flutter/material.dart';

import 'cores.dart';

/// O tema escuro do app, no visual do site.
ThemeData criarTemaApp() {
  const esquema = ColorScheme.dark(
    primary: Cores.verde,
    onPrimary: Colors.white,
    secondary: Cores.amarelo,
    onSecondary: Cores.fundo,
    error: Cores.vermelho,
    onError: Cores.fundo,
    surface: Cores.fundo,
    onSurface: Cores.texto,
  );

  final cantosDoBotao = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  const textoDoBotao = TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w700,
    fontSize: 14,
    letterSpacing: 0.5,
  );

  return ThemeData(
    colorScheme: esquema,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: Cores.fundo,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Cores.texto,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    // .btn-mt: verde, texto branco em maiúsculas (escritas em cada botão) e altura de toque de 48.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Cores.verde,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Cores.seloVerdeFundo,
        disabledForegroundColor: Cores.textoSuave,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: cantosDoBotao,
        textStyle: textoDoBotao,
      ),
    ),
    // .btn-mt-secundario: branco a 8%, com borda.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Cores.seloCinzaFundo,
        foregroundColor: Cores.texto,
        side: const BorderSide(color: Cores.borda),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: cantosDoBotao,
        textStyle: textoDoBotao,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Cores.painel,
      labelStyle: const TextStyle(color: Cores.textoSuave),
      floatingLabelStyle: const TextStyle(color: Cores.verdeForte),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Cores.borda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Cores.verdeForte, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Cores.vermelho),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Cores.vermelho, width: 2),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Cores.amarelo),
  );
}
