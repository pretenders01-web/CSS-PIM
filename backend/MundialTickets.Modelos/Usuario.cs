using System.ComponentModel.DataAnnotations;
using MundialTickets.Modelos.Constantes;

namespace MundialTickets.Modelos;

// Entidade de negócio: representa uma linha da tabela Usuario.
// Implementa IValidavel: a própria classe sabe conferir os dados básicos.
public class Usuario : IValidavel
{
    public int UsuarioID { get; set; }

    [Required, StringLength(100)]
    public string Nome { get; set; } = string.Empty;

    [Required, StringLength(150), EmailAddress]
    public string Email { get; set; } = string.Empty;

    // Guarda só o hash da senha, nunca a senha. Esta propriedade não sai em nenhum DTO.
    [Required, StringLength(255)]
    public string SenhaHash { get; set; } = string.Empty;

    // Opcional, como no banco e no formulário de cadastro. Quando informado, só os dígitos.
    [StringLength(14)]
    public string? CPF { get; set; }

    // Preenchida pelo banco (default getdate()) quando o usuário é criado.
    public DateTime DataCadastro { get; set; }

    // Usuário desativado não consegue entrar. A conta nunca é apagada de fato, porque o
    // banco recusa a exclusão de quem já tem vendas.
    public bool Ativo { get; set; } = true;

    // CLIENTE ou ADMIN (ver PerfilUsuario). O cadastro cria sempre CLIENTE.
    [Required, StringLength(20)]
    public string Perfil { get; set; } = PerfilUsuario.Cliente;

    // Relacionamento (navegação).
    public ICollection<Venda> Vendas { get; set; } = new List<Venda>();

    // Confere os dados básicos. O CPF é opcional, por isso não entra aqui.
    public bool Validar() =>
        !string.IsNullOrWhiteSpace(Nome)
        && !string.IsNullOrWhiteSpace(Email)
        && Email.Contains('@');
}
