using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de ENTRADA do cadastro (tela de Cadastro e POST /api/usuarios).
// Não tem Perfil nem Ativo: quem se cadastra é sempre CLIENTE e ativo, e ninguém consegue
// forjar isso pelo corpo da requisição, porque o campo não existe aqui.
public class UsuarioCadastroDto
{
    [Display(Name = "Nome")]
    [Required(ErrorMessage = "Informe o nome.")]
    [StringLength(100, ErrorMessage = "O nome pode ter no máximo 100 caracteres.")]
    public string Nome { get; set; } = string.Empty;

    [Display(Name = "E-mail")]
    [Required(ErrorMessage = "Informe o e-mail.")]
    [StringLength(150, ErrorMessage = "O e-mail pode ter no máximo 150 caracteres.")]
    [EmailAddress(ErrorMessage = "E-mail inválido.")]
    public string Email { get; set; } = string.Empty;

    // Opcional, como no banco e no formulário de cadastro do site.
    [Display(Name = "CPF")]
    [StringLength(14, ErrorMessage = "O CPF pode ter no máximo 14 caracteres.")]
    public string? Cpf { get; set; }

    // A senha só existe aqui, em texto, até o Negocio transformá-la em hash.
    [Display(Name = "Senha")]
    [Required(ErrorMessage = "Informe a senha.")]
    [StringLength(100, ErrorMessage = "A senha pode ter no máximo 100 caracteres.")]
    public string Senha { get; set; } = string.Empty;

    [Display(Name = "Confirme sua senha")]
    [Required(ErrorMessage = "Confirme a senha.")]
    [Compare(nameof(Senha), ErrorMessage = "As senhas não conferem.")]
    public string ConfirmarSenha { get; set; } = string.Empty;

    // Converte o que foi digitado na entidade (ainda sem o hash, que o Negocio gera).
    public Usuario ParaUsuario() => new()
    {
        Nome = Nome,
        Email = Email,
        CPF = string.IsNullOrWhiteSpace(Cpf) ? null : Cpf
    };
}
