import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modelos/ingresso_validado.dart';
import '../servicos/erros_api.dart';
import '../servicos/ingresso_servico.dart';
import '../tema/cores.dart';
import '../util/formatacao.dart';
import '../widgets/leitor_camera.dart';

/// Monta o leitor de QR. Os testes passam um falso, porque a câmera não existe no teste.
typedef ConstrutorDoLeitor = Widget Function(BuildContext context, void Function(String codigo) aoLer);

Widget _leitorReal(BuildContext context, void Function(String codigo) aoLer) => LeitorCamera(aoLer: aoLer);

/// As três etapas da tela. Só se lê um código novo na etapa "lendo".
enum _Etapa { lendo, validando, resultado }

enum _TipoDoResultado { liberado, recusado, indefinido }

/// Modo Portaria: valida o ingresso pela câmera ou pelo código digitado ou colado.
/// A verificação do perfil no app só decide se o botão aparece: quem protege a rota é a Api.
class PortariaTela extends StatefulWidget {
  const PortariaTela({super.key, required this.ingressos, this.construirLeitor = _leitorReal});

  final IngressoServico ingressos;
  final ConstrutorDoLeitor construirLeitor;

  @override
  State<PortariaTela> createState() => _PortariaTelaState();
}

class _PortariaTelaState extends State<PortariaTela> {
  final _campoCodigo = TextEditingController();

  _Etapa _etapa = _Etapa.lendo;
  _TipoDoResultado? _tipo;
  IngressoValidado? _validado;
  String? _mensagem;
  String? _erroDoCampo;

  @override
  void dispose() {
    _campoCodigo.dispose();
    super.dispose();
  }

  void _validarCampo() {
    final codigo = _campoCodigo.text.trim();
    if (codigo.isEmpty) {
      setState(() => _erroDoCampo = 'Informe o código do ingresso.');
      return;
    }
    _validar(codigo);
  }

  /// A câmera e o campo chegam aqui, na mesma validação.
  /// Fora de "lendo", ignora: a câmera detecta o mesmo QR repetidamente, e sem esta trava a segunda
  /// leitura trocaria o verde por um vermelho de "já utilizado".
  Future<void> _validar(String codigoLido) async {
    if (_etapa != _Etapa.lendo) return;

    final codigo = codigoLido.trim();
    if (codigo.isEmpty) return;

    setState(() {
      _etapa = _Etapa.validando;
      _erroDoCampo = null;
    });

    try {
      final validado = await widget.ingressos.validar(codigo);
      HapticFeedback.mediumImpact();
      _mostrarResultado(_TipoDoResultado.liberado, validado: validado);
    } on SessaoExpiradaException {
      // O app.dart já está levando de volta ao login.
    } on SemConexaoException {
      // Falha de rede não é recusa: o ingresso não foi recusado por ninguém.
      _mostrarResultado(_TipoDoResultado.indefinido, mensagem: 'Não foi possível validar. Tente de novo.');
    } on ApiException catch (erro) {
      if (erro.codigo == 400) {
        HapticFeedback.heavyImpact();
        _mostrarResultado(_TipoDoResultado.recusado, mensagem: erro.mensagem);
      } else {
        _mostrarResultado(_TipoDoResultado.indefinido, mensagem: erro.mensagem);
      }
    }
  }

  void _mostrarResultado(_TipoDoResultado tipo, {IngressoValidado? validado, String? mensagem}) {
    if (!mounted) return;
    setState(() {
      _etapa = _Etapa.resultado;
      _tipo = tipo;
      _validado = validado;
      _mensagem = mensagem;
    });
  }

  void _voltarAoInicio() {
    setState(() {
      // No resultado indefinido, o código continua no campo para tentar de novo.
      if (_tipo != _TipoDoResultado.indefinido) _campoCodigo.clear();
      _etapa = _Etapa.lendo;
      _tipo = null;
      _validado = null;
      _mensagem = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_etapa == _Etapa.resultado) {
      return _TelaDeResultado(
        tipo: _tipo!,
        validado: _validado,
        mensagem: _mensagem,
        aoContinuar: _voltarAoInicio,
      );
    }

    final validando = _etapa == _Etapa.validando;
    final alturaDaCamera = math.min(MediaQuery.sizeOf(context).height * 0.4, 360.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Portaria')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: alturaDaCamera,
                  // A câmera só fica montada na etapa de leitura.
                  child: validando
                      ? const ColoredBox(
                          color: Cores.painelOpaco,
                          child: Center(child: CircularProgressIndicator(semanticsLabel: 'Validando o ingresso')),
                        )
                      : widget.construirLeitor(context, _validar),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Aponte a câmera para o QR Code do ingresso.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Cores.textoSuave),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ou digite o código',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _campoCodigo,
                enabled: !validando,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(labelText: 'Código do ingresso', errorText: _erroDoCampo),
                onSubmitted: (_) => _validarCampo(),
              ),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: validando ? null : _validarCampo, child: const Text('VALIDAR')),
            ],
          ),
        ),
      ),
    );
  }
}

/// A resposta grande: cor, ícone e texto juntos, para não depender só da cor nem de som.
class _TelaDeResultado extends StatelessWidget {
  const _TelaDeResultado({
    required this.tipo,
    required this.validado,
    required this.mensagem,
    required this.aoContinuar,
  });

  final _TipoDoResultado tipo;
  final IngressoValidado? validado;
  final String? mensagem;
  final VoidCallback aoContinuar;

  @override
  Widget build(BuildContext context) {
    // Branco sobre o vermelho do site reprova no contraste (3,27). Por isso o texto é escuro (5,94).
    final (fundo, corDoTexto, icone, titulo) = switch (tipo) {
      _TipoDoResultado.liberado => (Cores.verde, Colors.white, Icons.check_circle, 'ENTRADA LIBERADA'),
      _TipoDoResultado.recusado => (Cores.vermelho, Cores.fundo, Icons.cancel, 'ENTRADA RECUSADA'),
      _TipoDoResultado.indefinido => (Cores.fundo, Colors.white, Icons.wifi_off, 'NÃO VALIDADO'),
    };

    final dados = validado;
    final assento = dados?.numeroAssento ?? '—';

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: fundo,
        foregroundColor: corDoTexto,
        elevation: 0,
        title: const Text('Portaria'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, limites) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: limites.maxHeight - 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          icone,
                          size: 96,
                          color: tipo == _TipoDoResultado.indefinido ? Cores.amarelo : corDoTexto,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          titulo,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: corDoTexto, fontSize: 30, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 20),
                        if (mensagem != null)
                          Text(
                            mensagem!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: corDoTexto, fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                        if (dados != null) ...[
                          Text(
                            dados.partida,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: corDoTexto, fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${dados.nomeSetor}\nAssento $assento\n${formatarDataHora(dados.dataJogo)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: corDoTexto, fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: tipo == _TipoDoResultado.indefinido
                        ? null
                        : ElevatedButton.styleFrom(backgroundColor: Cores.fundo, foregroundColor: Colors.white),
                    onPressed: aoContinuar,
                    child: Text(tipo == _TipoDoResultado.indefinido ? 'TENTAR DE NOVO' : 'LER PRÓXIMO'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
