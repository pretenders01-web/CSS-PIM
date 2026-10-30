using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de SAÍDA: o que o sistema MOSTRA de um usuário.
// Não tem SenhaHash de propósito: o hash da senha nunca sai do sistema.
public class UsuarioDto
{
    public int Id { get; set; }

    [Display(Name = "Nome")]
    public string Nome { get; set; } = string.Empty;

    [Display(Name = "E-mail")]
    public string Email { get; set; } = string.Empty;

    [Display(Name = "CPF")]
    public string? Cpf { get; set; }

    [Display(Name = "Cadastrado em")]
    public DateTime DataCadastro { get; set; }

    [Display(Name = "Ativo")]
    public bool Ativo { get; set; }

    [Display(Name = "Perfil")]
    public string Perfil { get; set; } = string.Empty;

    public static UsuarioDto De(Usuario u) => new()
    {
        Id = u.UsuarioID,
        Nome = u.Nome,
        Email = u.Email,
        Cpf = u.CPF,
        DataCadastro = u.DataCadastro,
        Ativo = u.Ativo,
        Perfil = u.Perfil
    };
}
