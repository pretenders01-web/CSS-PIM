import 'package:flutter/material.dart';

import '../util/layout.dart';

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
      appBar: AppBar(toolbarHeight: alturaDaBarra(context), title: const Text('Ler QR Code')),
      body: SafeArea(
        // A mesma árvore em pé e deitado: girar não remonta o leitor, e a câmera não reinicia.
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.construirLeitor(context, _aoLer),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ColoredBox(
                color: Color(0xB3000000),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Aponte a câmera para o QR Code do ingresso.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
