import 'package:flutter/material.dart';

import '../servicos/autenticacao_servico.dart';
import '../servicos/erros_api.dart';
import '../tema/cores.dart';
import '../util/validadores.dart';

/// Entrada com a conta criada no site. O app não tem cadastro nem compra.
class LoginTela extends StatefulWidget {
  const LoginTela({super.key, required this.autenticacao});

  final AutenticacaoServico autenticacao;

  @override
  State<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends State<LoginTela> {
  final _formulario = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();

  bool _enviando = false;
  bool _mostrarSenha = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _erro = widget.autenticacao.avisoDoLogin;
  }

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_enviando) return;
    if (!_formulario.currentState!.validate()) return;

    setState(() {
      _enviando = true;
      _erro = null;
    });

    try {
      await widget.autenticacao.entrar(_email.text.trim(), _senha.text);
      // Deu certo: o app.dart troca de tela sozinho, ao ver a sessão nova.
      _senha.clear();
    } on ApiException catch (erro) {
      _mostrarErro(erro.mensagem);
    } on SemConexaoException {
      _mostrarErro(SemConexaoException.mensagem);
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _erro = mensagem;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Rolável, para o teclado e as fontes grandes não cortarem nada.
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formulario,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'assets/img/logo.png',
                        height: 84,
                        cacheWidth: 768,
                        semanticLabel: 'Mundial Tickets',
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Faça login',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Cores.verdeForte,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _email,
                        enabled: !_enviando,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        decoration: const InputDecoration(labelText: 'E-mail'),
                        validator: validarEmail,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _senha,
                        enabled: !_enviando,
                        obscureText: !_mostrarSenha,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          suffixIcon: IconButton(
                            tooltip: _mostrarSenha ? 'Esconder a senha' : 'Mostrar a senha',
                            icon: Icon(_mostrarSenha ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
                          ),
                        ),
                        validator: validarSenha,
                        onFieldSubmitted: (_) => _entrar(),
                      ),
                      if (_erro != null) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: Text(_erro!, style: const TextStyle(color: Cores.vermelho)),
                        ),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _enviando ? null : _entrar,
                        child: _enviando
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  semanticsLabel: 'Entrando',
                                ),
                              )
                            : const Text('ENTRAR'),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'O cadastro e a compra de ingressos são feitos no site Mundial Tickets.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Cores.textoSuave),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
