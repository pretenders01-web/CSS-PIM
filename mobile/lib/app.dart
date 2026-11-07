import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/configuracao_api.dart';
import 'modelos/situacao_ingresso.dart';
import 'tema/tema_app.dart';
import 'telas/configuracao_ausente_tela.dart';
import 'widgets/cartao_vidro.dart';
import 'widgets/selo_ingresso.dart';

class MundialTicketsApp extends StatelessWidget {
  const MundialTicketsApp({super.key, required this.configuracao});

  final ConfiguracaoApi configuracao;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mundial Tickets',
      debugShowCheckedModeBanner: false,
      theme: criarTemaApp(),
      // Em pt-BR, para o leitor de tela dizer "Voltar", e não "Back".
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: configuracao.valida
          ? const _BaseTela()
          : ConfiguracaoAusenteTela(mensagem: configuracao.erro!),
    );
  }
}

/// Tela provisória da Parte 2A: mostra os elementos do tema. O login a substitui na Parte 2B.
class _BaseTela extends StatelessWidget {
  const _BaseTela();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CartaoVidro(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/img/logo.png', height: 72, cacheWidth: 600),
                const SizedBox(height: 16),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SeloIngresso(situacao: SituacaoIngresso.valido),
                    SeloIngresso(situacao: SituacaoIngresso.utilizado),
                    SeloIngresso(situacao: SituacaoIngresso.expirado),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () {}, child: const Text('VALIDAR INGRESSO')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
