import 'package:flutter/material.dart';

import '../tema/cores.dart';

/// Monta o leitor de QR. Os testes passam um falso, porque a câmera não existe no teste.
typedef ConstrutorDoLeitor = Widget Function(BuildContext context, void Function(String codigo) aoLer);

/// A câmera em tela própria, aberta pelo botão "Ler QR Code". Devolve o código lido ao fechar.
/// É só aqui que o Android pede a permissão de câmera.
class LeitorQrTela extends StatefulWidget {
  const LeitorQrTela({super.key, required this.construirLeitor});

  final ConstrutorDoLeitor construirLeitor;

  @override
  State<LeitorQrTela> createState() => _LeitorQrTelaState();
}

class _LeitorQrTelaState extends State<LeitorQrTela> {
  bool _jaLeu = false;

  /// A câmera detecta o mesmo QR repetidamente, então só a primeira leitura vale.
  void _aoLer(String codigo) {
    if (_jaLeu || !mounted) return;
    _jaLeu = true;
    Navigator.of(context).pop(codigo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ler QR Code')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: widget.construirLeitor(context, _aoLer)),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Aponte a câmera para o QR Code do ingresso.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Cores.textoSuave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
