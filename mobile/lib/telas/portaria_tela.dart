import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modelos/ingresso_validado.dart';
import '../modelos/registro_validacao.dart';
import '../servicos/autenticacao_servico.dart';
import '../servicos/erros_api.dart';
import '../servicos/ingresso_servico.dart';
import '../tema/cores.dart';
import '../util/layout.dart';
import '../widgets/historico_validacoes.dart';
import '../widgets/leitor_camera.dart';
import '../widgets/resultado_validacao.dart';
import 'leitor_qr_tela.dart';

Widget _leitorReal(BuildContext context, void Function(String codigo) aoLer) => LeitorCamera(aoLer: aoLer);

/// As etapas da tela. Só se valida um código novo na etapa "lendo".
enum _Etapa { lendo, validando, resultado }

/// A tela de quem tem o perfil ADMIN: é onde ele cai depois do login, sem passar pela tela do torcedor.
/// O perfil só decide o que aparece: quem protege a validação é a Api.
class PortariaTela extends StatefulWidget {
  const PortariaTela({
    super.key,
    required this.autenticacao,
    required this.ingressos,
    this.construirLeitor = _leitorReal,
    this.relogio = DateTime.now,
    this.esperaDoResultado = const Duration(seconds: 5),
  });

  final AutenticacaoServico autenticacao;
  final IngressoServico ingressos;

  /// Parâmetros para os testes trocarem a câmera e controlarem o tempo.
  final ConstrutorDoLeitor construirLeitor;
  final DateTime Function() relogio;
  final Duration esperaDoResultado;

  @override
  State<PortariaTela> createState() => _PortariaTelaState();
}

class _PortariaTelaState extends State<PortariaTela> {
  final _campoCodigo = TextEditingController();

  /// Girar o aparelho muda o campo de lugar na árvore de widgets. Com esta chave, o Flutter o reaproveita,
  /// e o texto, o cursor e o foco continuam os mesmos.
  final _chaveDoCampo = GlobalKey();

  /// O histórico desta sessão, do mais recente ao mais antigo. Só em memória: some ao sair.
  final List<RegistroValidacao> _historico = [];

  _Etapa _etapa = _Etapa.lendo;
  RegistroValidacao? _resultado;
  String? _erroDoCampo;

  int get _entradasLiberadas => _historico.where((r) => r.resultado == ResultadoValidacao.liberada).length;

  @override
  void dispose() {
    _campoCodigo.dispose();
    super.dispose();
  }

  Future<void> _abrirCamera() async {
    final codigo = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => LeitorQrTela(construirLeitor: widget.construirLeitor)),
    );
    if (codigo != null && mounted) await _validar(codigo);
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
      _registrarLiberada(codigo, validado);
    } on SessaoExpiradaException {
      // O app.dart já está levando de volta ao login.
    } on SemConexaoException {
      // Falha de rede não é recusa: o ingresso não foi recusado por ninguém.
      _registrarFalha(codigo, ResultadoValidacao.naoValidada, 'Não foi possível validar. Tente de novo.');
    } on ApiException catch (erro) {
      if (erro.codigo == 400) {
        HapticFeedback.heavyImpact();
        _registrarFalha(codigo, ResultadoValidacao.recusada, erro.mensagem);
      } else {
        _registrarFalha(codigo, ResultadoValidacao.naoValidada, erro.mensagem);
      }
    }
  }

  void _registrarLiberada(String codigo, IngressoValidado validado) {
    _mostrar(RegistroValidacao.liberada(codigo, widget.relogio(), validado));
  }

  /// A recusa da Api traz só o motivo. Se o mesmo código já passou por aqui, o histórico sabe a partida.
  void _registrarFalha(String codigo, ResultadoValidacao resultado, String motivo) {
    final conhecido = _historico.where((r) => r.codigo == codigo && r.partida != null).firstOrNull;
    _mostrar(
      RegistroValidacao(
        horario: widget.relogio(),
        codigo: codigo,
        resultado: resultado,
        motivo: motivo,
        partida: conhecido?.partida,
        nomeSetor: conhecido?.nomeSetor,
        numeroAssento: conhecido?.numeroAssento,
        dataJogo: conhecido?.dataJogo,
      ),
    );
  }

  void _mostrar(RegistroValidacao registro) {
    if (!mounted) return;
    setState(() {
      _historico.insert(0, registro);
      _resultado = registro;
      _etapa = _Etapa.resultado;
      // Sem resposta da Api, o código fica no campo, para tentar de novo. Vale também para o da câmera.
      if (registro.resultado == ResultadoValidacao.naoValidada) {
        _campoCodigo.text = registro.codigo;
      } else {
        _campoCodigo.clear();
      }
    });
  }

  /// Volta à tela de leitura, e não à câmera: o mesmo QR ainda pode estar na frente dela, e uma
  /// segunda leitura trocaria o verde por um vermelho de "já utilizado".
  void _voltarALeitura() {
    if (!mounted) return;
    setState(() {
      _etapa = _Etapa.lendo;
      _resultado = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_etapa == _Etapa.resultado) {
      return ResultadoValidacaoTela(
        registro: _resultado!,
        espera: widget.esperaDoResultado,
        aoVoltar: _voltarALeitura,
      );
    }

    final validando = _etapa == _Etapa.validando;
    final deitado = estaDeitado(context);
    final margem = margemLateral(context);

    final contador = ContadorDeEntradas(liberadas: _entradasLiberadas);

    final leitura = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: Size.fromHeight(deitado ? 72 : 80),
            textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w800),
          ),
          onPressed: validando ? null : _abrirCamera,
          icon: validando
              ? const SizedBox.square(
                  dimension: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    semanticsLabel: 'Validando o ingresso',
                  ),
                )
              : const Icon(Icons.qr_code_scanner, size: 32),
          label: const Text('LER QR CODE'),
        ),
        SizedBox(height: deitado ? 12 : 20),
        const Text('Ou digite ou cole o código', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          key: _chaveDoCampo,
          controller: _campoCodigo,
          enabled: !validando,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.send,
          decoration: InputDecoration(labelText: 'Código do ingresso', errorText: _erroDoCampo),
          onSubmitted: (_) => _validarCampo(),
        ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: validando ? null : _validarCampo, child: const Text('VALIDAR')),
      ],
    );

    final historico = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: const Text(
            'Validações desta sessão',
            style: TextStyle(color: Cores.texto, fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 8),
        HistoricoValidacoes(registros: _historico),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: alturaDaBarra(context),
        title: Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Image.asset(
                'assets/img/logo.png',
                height: 32,
                cacheWidth: 330,
                semanticLabel: 'Mundial Tickets',
              ),
            ),
            const SizedBox(width: 12),
            // Encolhe em tela estreita com fonte grande, em vez de estourar a barra.
            const Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Portaria', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: widget.autenticacao.sair,
          ),
        ],
      ),
      body: SafeArea(
        // Deitado: a leitura à esquerda, e o contador e o histórico à direita, cada lado com a sua rolagem.
        // O histórico, o contador e o resultado ficam neste State, e girar não os apaga.
        child: deitado
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(margem, 12, 8, 12),
                      child: leitura,
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(8, 12, margem, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [contador, const SizedBox(height: 12), historico],
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: margem, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [contador, const SizedBox(height: 16), leitura, const SizedBox(height: 24), historico],
                ),
              ),
      ),
    );
  }
}
