using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de SAÍDA: o que o sistema MOSTRA de um cliente.
// DTO = Data Transfer Object, um objeto só para transportar dados.
//   - A Api devolve este objeto como JSON para o aplicativo Flutter.
//   - A Web usa este objeto nas telas de listagem e de exclusão.
// Por que não usar a entidade Cliente direto? Porque aí qualquer coluna nova
// na tabela vazaria para o app e para as telas. O DTO escolhe o que sai.
public class ClienteDto
{
    public int Id { get; set; }

    [Display(Name = "Nome")]
    public string Nome { get; set; } = string.Empty;

    [Display(Name = "E-mail")]
    public string Email { get; set; } = string.Empty;

    [Display(Name = "CPF")]
    public string Cpf { get; set; } = string.Empty;

    [Display(Name = "Cadastrado em")]
    public DateTime DataCadastro { get; set; }

    [Display(Name = "Ativo")]
    public bool Ativo { get; set; }

    // Converte a entidade (que vem do Negocio) no DTO (que vai para a tela ou o app).
    public static ClienteDto De(Cliente c) => new()
    {
        Id = c.Id,
        Nome = c.Nome,
        Email = c.Email,
        Cpf = c.Cpf,
        DataCadastro = c.DataCadastro,
        Ativo = c.Ativo
    };
}
