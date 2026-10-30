using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de SAÍDA: o que o sistema MOSTRA de um estádio.
//   - A Api devolve este objeto como JSON para o aplicativo Flutter.
//   - A Web usa este objeto nas telas de listagem e de exclusão.
// Por que não usar a entidade Estadio direto? Porque aí qualquer coluna nova
// na tabela vazaria para o app e para as telas. O DTO escolhe o que sai.
public class EstadioDto
{
    public int Id { get; set; }

    [Display(Name = "Nome")]
    public string Nome { get; set; } = string.Empty;

    [Display(Name = "Cidade")]
    public string Cidade { get; set; } = string.Empty;

    [Display(Name = "Capacidade total")]
    public int CapacidadeTotal { get; set; }

    // Converte a entidade (que vem do Negocio) no DTO (que vai para a tela ou o app).
    public static EstadioDto De(Estadio e) => new()
    {
        Id = e.EstadioID,
        Nome = e.Nome,
        Cidade = e.Cidade,
        CapacidadeTotal = e.CapacidadeTotal
    };
}
