// Validação dos campos do login, com as mesmas mensagens do LoginDto da Api.

String? validarEmail(String? valor) {
  final email = (valor ?? '').trim();
  if (email.isEmpty) return 'Informe o e-mail.';

  // A mesma regra do [EmailAddress] da Api: um único @, que não fica nas pontas.
  final arroba = email.indexOf('@');
  final valido = arroba > 0 && arroba == email.lastIndexOf('@') && arroba < email.length - 1;
  return valido ? null : 'E-mail inválido.';
}

String? validarSenha(String? valor) {
  if ((valor ?? '').isEmpty) return 'Informe a senha.';
  return null;
}
