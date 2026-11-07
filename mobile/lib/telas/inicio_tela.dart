import 'package:flutter/material.dart';

import '../modelos/ingresso.dart';
import '../modelos/situacao_ingresso.dart';
import '../servicos/autenticacao_servico.dart';
import '../servicos/erros_api.dart';
import '../servicos/ingresso_servico.dart';
import '../tema/cores.dart';
import '../util/como_chegar.dart';
import '../widgets/cartao_ingresso.dart';
import '../widgets/cartao_proximo_jogo.dart';
import '../widgets/estados_tela.dart';
import '../widgets/fundo_cartao_hero.dart';
import 'portaria_tela.dart';
import 'qr_tela.dart';

/// A tela inicial: o cartão do próximo jogo e, abaixo, os outros ingressos.
class InicioTela extends StatefulWidget {
  const InicioTela({
    super.key,
    required this.autenticacao,
    required this.ingressos,
    this.relogio = DateTime.now,
    this.abrirLink = abrirLinkExterno,
  });

  final AutenticacaoServico autenticacao;
  final IngressoServico ingressos;

  /// Parâmetros para os testes controlarem a hora e não abrirem o navegador.
  final DateTime Function() relogio;
  final Future<bool> Function(Uri) abrirLink;

  @override
  State<InicioTela> createState() => _InicioTelaState();
}

class _InicioTelaState extends State<InicioTela> {
  List<Ingresso>? _lista;
  String? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  /// Sem tela de carregando quando já há dados: a lista só muda quando a resposta chega.
  Future<void> _carregar() async {
    try {
      final lista = await widget.ingressos.listarMeusIngressos();
      if (!mounted) return;
      setState(() {
        _lista = lista;
        _erro = null;
        _carregando = false;
      });
    } on SessaoExpiradaException {
      // O app.dart já está levando de volta ao login.
    } on SemConexaoException {
      _mostrarErro(SemConexaoException.mensagem);
    } on ApiException catch (erro) {
      _mostrarErro(erro.mensagem);
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    if (_lista != null) {
      // Falhou ao atualizar, mas já há o que mostrar: só avisa.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
      return;
    }
    setState(() {
      _erro = mensagem;
      _carregando = false;
    });
  }

  void _tentarDeNovo() {
    setState(() {
      _erro = null;
      _carregando = true;
    });
    _carregar();
  }

  Future<void> _comoChegar(Ingresso ingresso) async {
    final abriu = await widget.abrirLink(enderecoDoMapa(ingresso.estadioNome, ingresso.estadioCidade));
    if (!abriu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o mapa.')),
      );
    }
  }

  /// Ao voltar, recarrega: o ingresso pode ter sido validado com a tela do QR aberta.
  Future<void> _abrirQr(Ingresso ingresso) async {
    await Navigator.of(context).push(
      rotaDoCartao<void>(
        (_) => QrTela(ingresso: ingresso, ingressos: widget.ingressos, relogio: widget.relogio),
      ),
    );
    if (mounted) await _carregar();
  }

  /// Ao voltar, recarrega: o administrador pode ter validado um ingresso da própria conta.
  Future<void> _abrirPortaria() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PortariaTela(ingressos: widget.ingressos)),
    );
    if (mounted) await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final ehAdmin = widget.autenticacao.sessao.value?.usuario.ehAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/img/logo.png',
          height: 36,
          cacheWidth: 500,
          semanticLabel: 'Mundial Tickets',
        ),
        actions: [
          // A Api é quem protege a validação. Aqui, o perfil só decide o que aparece.
          if (ehAdmin)
            IconButton(
              tooltip: 'Portaria',
              icon: const Icon(Icons.qr_code_scanner, color: Cores.amarelo),
              onPressed: _abrirPortaria,
            ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: widget.autenticacao.sair,
          ),
        ],
      ),
      body: SafeArea(child: _construirCorpo()),
    );
  }

  Widget _construirCorpo() {
    if (_carregando) return const EstadoCarregando();

    if (_erro != null) {
      return _Rolavel(
        aoAtualizar: _carregar,
        child: EstadoErro(mensagem: _erro!, aoTentarDeNovo: _tentarDeNovo),
      );
    }

    final lista = _lista!;
    if (lista.isEmpty) {
      return _Rolavel(
        aoAtualizar: _carregar,
        child: const EstadoVazio(
          titulo: 'Você ainda não tem ingressos',
          detalhe: 'A compra é feita no site Mundial Tickets. Depois, puxe esta tela para atualizar.',
        ),
      );
    }

    final agora = widget.relogio();
    final separados = separarIngressos(lista, agora);
    final proximo = separados.proximo;
    final outros = separados.outros;

    // ListView.builder: o que está longe na lista não fica montado.
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 1 + (outros.isEmpty ? 0 : 1 + outros.length),
        itemBuilder: (context, indice) {
          if (indice == 0) {
            if (proximo == null) {
              return const EstadoVazio(
                titulo: 'Nenhum próximo jogo',
                detalhe: 'Seus ingressos já foram usados ou os jogos já passaram.',
              );
            }
            return CartaoProximoJogo(
              ingresso: proximo,
              aoValidar: () => _abrirQr(proximo),
              aoComoChegar: () => _comoChegar(proximo),
            );
          }

          if (indice == 1) {
            return Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 8),
              child: Semantics(
                header: true,
                child: Text(
                  proximo == null ? 'Seus ingressos' : 'Outros ingressos',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            );
          }

          final ingresso = outros[indice - 2];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CartaoIngresso(
              ingresso: ingresso,
              situacao: situacaoDoIngresso(ingresso, agora),
              aoTocar: () => _abrirQr(ingresso),
            ),
          );
        },
      ),
    );
  }
}

/// Os estados de vazio e de erro também aceitam "puxar para atualizar".
class _Rolavel extends StatelessWidget {
  const _Rolavel({required this.aoAtualizar, required this.child});

  final Future<void> Function() aoAtualizar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: aoAtualizar,
      child: LayoutBuilder(
        builder: (context, limites) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: limites.maxHeight),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
