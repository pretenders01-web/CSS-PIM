import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;

import 'config/configuracao_api.dart';
import 'modelos/sessao.dart';
import 'servicos/armazenamento_sessao.dart';
import 'servicos/autenticacao_servico.dart';
import 'servicos/cliente_api.dart';
import 'servicos/ingresso_servico.dart';
import 'tema/tema_app.dart';
import 'telas/configuracao_ausente_tela.dart';
import 'telas/inicio_tela.dart';
import 'telas/login_tela.dart';
import 'telas/portaria_tela.dart';
import 'widgets/estados_tela.dart';

/// Em pé e deitado para os dois lados. De cabeça para baixo fica de fora, como na maioria dos celulares.
const List<DeviceOrientation> orientacoesDoApp = [
  DeviceOrientation.portraitUp,
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];

/// Os serviços do app, montados uma vez e passados pelo construtor de cada tela.
/// Os testes montam este mesmo objeto com versões falsas.
class ServicosDoApp {
  ServicosDoApp({required this.autenticacao, required this.ingressos});

  factory ServicosDoApp.reais(String enderecoBase) {
    final api = ClienteApi(cliente: http.Client(), enderecoBase: enderecoBase);
    return ServicosDoApp(
      autenticacao: AutenticacaoServico(api: api, armazenamento: ArmazenamentoSeguro()),
      ingressos: IngressoServico(api: api),
    );
  }

  final AutenticacaoServico autenticacao;
  final IngressoServico ingressos;
}

class MundialTicketsApp extends StatefulWidget {
  const MundialTicketsApp({super.key, required this.configuracao, this.servicos});

  final ConfiguracaoApi configuracao;

  /// Os testes passam serviços falsos. No app real, fica nulo e os serviços são criados aqui.
  final ServicosDoApp? servicos;

  @override
  State<MundialTicketsApp> createState() => _MundialTicketsAppState();
}

class _MundialTicketsAppState extends State<MundialTicketsApp> {
  final _navegador = GlobalKey<NavigatorState>();

  ServicosDoApp? _servicos;
  bool _restaurando = true;

  @override
  void initState() {
    super.initState();
    if (!widget.configuracao.valida) return;

    _servicos = widget.servicos ?? ServicosDoApp.reais(widget.configuracao.enderecoBase!);
    _servicos!.autenticacao.sessao.addListener(_aoMudarSessao);
    _restaurarSessao();
  }

  @override
  void dispose() {
    _servicos?.autenticacao.sessao.removeListener(_aoMudarSessao);
    super.dispose();
  }

  Future<void> _restaurarSessao() async {
    final autenticacao = _servicos!.autenticacao;
    await autenticacao.restaurar();
    if (!mounted) return;
    setState(() => _restaurando = false);
    unawaited(autenticacao.confirmarConta());
  }

  /// Sem sessão, o login aparece na raiz. Fecha o que estiver aberto por cima dela.
  void _aoMudarSessao() {
    if (_servicos!.autenticacao.sessao.value == null) {
      _navegador.currentState?.popUntil((rota) => rota.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mundial Tickets',
      navigatorKey: _navegador,
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
      home: _construirInicio(),
    );
  }

  Widget _construirInicio() {
    if (!widget.configuracao.valida) {
      return ConfiguracaoAusenteTela(mensagem: widget.configuracao.erro!);
    }
    if (_restaurando) return const Scaffold(body: EstadoCarregando());

    final autenticacao = _servicos!.autenticacao;
    return ValueListenableBuilder<Sessao?>(
      valueListenable: autenticacao.sessao,
      builder: (context, sessao, _) {
        if (sessao == null) return LoginTela(autenticacao: autenticacao);

        // A mesma regra vale depois do login e ao abrir o app com a sessão salva.
        if (sessao.usuario.ehAdmin) {
          return PortariaTela(
            key: ValueKey(sessao.usuario.id),
            autenticacao: autenticacao,
            ingressos: _servicos!.ingressos,
          );
        }

        return InicioTela(
          key: ValueKey(sessao.usuario.id),
          autenticacao: autenticacao,
          ingressos: _servicos!.ingressos,
        );
      },
    );
  }
}
