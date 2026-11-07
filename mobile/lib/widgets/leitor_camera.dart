import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../tema/cores.dart';

/// A câmera da Portaria. Sem passar um controller, o MobileScanner cria o dele, para a câmera quando
/// o app vai para segundo plano, religa na volta e descarta tudo ao sair da tela. O pedido de
/// permissão também só aparece aqui, ao montar este widget.
class LeitorCamera extends StatelessWidget {
  const LeitorCamera({super.key, required this.aoLer});

  final void Function(String codigo) aoLer;

  void _aoDetectar(BarcodeCapture captura) {
    for (final codigo in captura.barcodes) {
      final texto = codigo.rawValue;
      // Só QR: um código de barras qualquer na frente da câmera não deve virar uma recusa.
      if (codigo.format == BarcodeFormat.qrCode && texto != null && texto.isNotEmpty) {
        aoLer(texto);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Câmera para ler o QR Code do ingresso',
      child: MobileScanner(
        onDetect: _aoDetectar,
        errorBuilder: (context, erro) => ErroDaCamera(codigo: erro.errorCode),
      ),
    );
  }
}

/// Aparece no lugar da câmera. O campo de digitar o código, na tela anterior, continua funcionando.
class ErroDaCamera extends StatelessWidget {
  const ErroDaCamera({super.key, required this.codigo});

  final MobileScannerErrorCode codigo;

  @override
  Widget build(BuildContext context) {
    final mensagem = codigo == MobileScannerErrorCode.permissionDenied
        ? 'Sem permissão para usar a câmera. Libere nas configurações do aparelho, ou volte e digite o código.'
        : 'Não foi possível abrir a câmera. Volte e digite o código.';

    return ColoredBox(
      color: Cores.painelOpaco,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(mensagem, textAlign: TextAlign.center, style: const TextStyle(color: Cores.textoSuave)),
        ),
      ),
    );
  }
}
