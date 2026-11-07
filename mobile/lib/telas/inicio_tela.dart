import 'package:flutter/material.dart';

import '../servicos/autenticacao_servico.dart';

/// Tela provisória da Parte 2B: a tela inicial de verdade chega na Parte 2C.
class InicioTela extends StatelessWidget {
  const InicioTela({super.key, required this.autenticacao});

  final AutenticacaoServico autenticacao;

  @override
  Widget build(BuildContext context) {
    final usuario = autenticacao.sessao.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mundial Tickets'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: autenticacao.sair,
          ),
        ],
      ),
      body: Center(child: Text('Olá, ${usuario?.usuario.nome ?? ''}!')),
    );
  }
}
