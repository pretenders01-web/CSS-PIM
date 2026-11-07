import 'package:flutter/material.dart';

import '../tema/cores.dart';

/// Aparece quando o endereço da Api falta ou não é aceito (ver ConfiguracaoApi).
class ConfiguracaoAusenteTela extends StatelessWidget {
  const ConfiguracaoAusenteTela({super.key, required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_outlined, size: 56, color: Cores.amarelo),
                const SizedBox(height: 16),
                Text(mensagem, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
