import 'usuario.dart';

/// O que o login devolve e o app guarda no armazenamento seguro. A senha nunca entra aqui.
class Sessao {
  const Sessao({required this.token, required this.expiraEm, required this.usuario});

  final String token;

  /// Em UTC, como a Api envia.
  final DateTime expiraEm;
  final Usuario usuario;

  bool expirada(DateTime agora) => !expiraEm.isAfter(agora);

  factory Sessao.fromJson(Map<String, dynamic> json) => Sessao(
    token: json['token'] as String,
    expiraEm: DateTime.parse(json['expiraEm'] as String),
    usuario: Usuario.fromJson(json['usuario'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'token': token,
    'expiraEm': expiraEm.toUtc().toIso8601String(),
    'usuario': usuario.toJson(),
  };
}
