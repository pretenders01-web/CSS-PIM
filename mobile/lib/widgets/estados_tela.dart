import 'package:flutter/material.dart';

import '../tema/cores.dart';

/// Os estados comuns das telas: carregando, vazio e erro com "tentar de novo".
class EstadoCarregando extends StatelessWidget {
  const EstadoCarregando({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(semanticsLabel: 'Carregando'));
  }
}

class EstadoVazio extends StatelessWidget {
  const EstadoVazio({super.key, required this.titulo, this.detalhe});

  final String titulo;
  final String? detalhe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.confirmation_number_outlined, size: 56, color: Cores.textoSuave),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          if (detalhe != null) ...[
            const SizedBox(height: 8),
            Text(detalhe!, textAlign: TextAlign.center, style: const TextStyle(color: Cores.textoSuave)),
          ],
        ],
      ),
    );
  }
}

class EstadoErro extends StatelessWidget {
  const EstadoErro({super.key, required this.mensagem, required this.aoTentarDeNovo});

  final String mensagem;
  final VoidCallback aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 56, color: Cores.amarelo),
          const SizedBox(height: 12),
          Semantics(liveRegion: true, child: Text(mensagem, textAlign: TextAlign.center)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: aoTentarDeNovo, child: const Text('TENTAR DE NOVO')),
        ],
      ),
    );
  }
}
