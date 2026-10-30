using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de ENTRADA da alteração dos próprios dados (tela Minha conta e PUT /api/usuarios/me).
// Não tem Perfil nem Ativo: o usuário não muda o próprio papel nem se reativa.
// A nova senha é opcional: em branco, a senha atual continua valendo.
public class UsuarioAtualizarDto
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

    [Display(Name = "CPF")]
    [StringLength(14, ErrorMessage = "O CPF pode ter no máximo 14 caracteres.")]
    public string? Cpf { get; set; }

    [Display(Name = "Nova senha")]
    [StringLength(100, ErrorMessage = "A senha pode ter no máximo 100 caracteres.")]
    public string? NovaSenha { get; set; }

    [Display(Name = "Confirme a nova senha")]
    [Compare(nameof(NovaSenha), ErrorMessage = "As senhas não conferem.")]
    public string? ConfirmarNovaSenha { get; set; }

    // Caminho inverso: preenche o formulário de Minha conta com os dados atuais.
    public static UsuarioAtualizarDto De(Usuario u) => new()
    {
        Nome = u.Nome,
        Email = u.Email,
        Cpf = u.CPF
    };
}
