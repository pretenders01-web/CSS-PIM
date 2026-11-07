/// O usuário logado, como vem em `usuario` no login e em GET /api/usuarios/me.
class Usuario {
  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
    this.cpf,
  });

  final int id;
  final String nome;
  final String email;
  final String perfil;

  /// O CPF é opcional no cadastro.
  final String? cpf;

  /// O perfil guardado é o do login, o mesmo que está dentro do token, e é esse que a Api confere.
  bool get ehAdmin => perfil == 'ADMIN';

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'] as int,
    nome: json['nome'] as String,
    email: json['email'] as String,
    perfil: json['perfil'] as String,
    cpf: json['cpf'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'email': email,
    'perfil': perfil,
    'cpf': cpf,
  };
}
