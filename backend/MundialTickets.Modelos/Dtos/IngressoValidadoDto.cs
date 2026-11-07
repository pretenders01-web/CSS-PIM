using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de SAÍDA da validação na portaria: o que a tela de "entrada liberada" mostra.
// A data vai junto porque a validação aceita qualquer jogo futuro: é quem está na portaria
// que confere se o ingresso é mesmo do jogo de hoje.
public class IngressoValidadoDto
{
    public int IngressoId { get; set; }

    [Display(Name = "Partida")]
    public string Partida { get; set; } = string.Empty;

    [Display(Name = "Data do jogo")]
    public DateTime DataJogo { get; set; }

    [Display(Name = "Setor")]
    public string NomeSetor { get; set; } = string.Empty;

    [Display(Name = "Assento")]
    public string? NumeroAssento { get; set; }
}
