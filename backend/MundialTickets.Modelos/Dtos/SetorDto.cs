using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de SAÍDA: o que o sistema MOSTRA de um setor (telas e JSON da Api).
public class SetorDto
{
    public int Id { get; set; }

    public int EstadioId { get; set; }

    [Display(Name = "Nome do setor")]
    public string NomeSetor { get; set; } = string.Empty;

    [Display(Name = "Capacidade")]
    public int Capacidade { get; set; }

    [Display(Name = "Preço base")]
    public decimal PrecoBase { get; set; }

    // Converte a entidade (que vem do Negocio) no DTO (que vai para a tela ou o app).
    public static SetorDto De(Setor s) => new()
    {
        Id = s.SetorID,
        EstadioId = s.EstadioID,
        NomeSetor = s.NomeSetor,
        Capacidade = s.Capacidade,
        PrecoBase = s.PrecoBase
    };
}
