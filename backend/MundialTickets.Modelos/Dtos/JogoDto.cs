using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de SAÍDA: o que o sistema MOSTRA de um jogo (telas e JSON da Api).
// Traz o nome e a cidade do estádio para a tela não precisar de uma segunda consulta.
public class JogoDto
{
    public int Id { get; set; }

    public int EstadioId { get; set; }

    [Display(Name = "Estádio")]
    public string EstadioNome { get; set; } = string.Empty;

    [Display(Name = "Cidade")]
    public string EstadioCidade { get; set; } = string.Empty;

    [Display(Name = "Data e hora")]
    public DateTime DataHora { get; set; }

    [Display(Name = "Time A")]
    public string TimeA { get; set; } = string.Empty;

    [Display(Name = "Time B")]
    public string TimeB { get; set; } = string.Empty;

    [Display(Name = "Fase")]
    public string Fase { get; set; } = string.Empty;

    // Texto pronto para as telas, por exemplo "Brasil x Sérvia".
    public string Partida => $"{TimeA} x {TimeB}";

    // O estádio só vem preenchido quando a consulta pediu (Include); sem ele, o nome fica vazio.
    public static JogoDto De(Jogo j) => new()
    {
        Id = j.JogoID,
        EstadioId = j.EstadioID,
        EstadioNome = j.Estadio?.Nome ?? string.Empty,
        EstadioCidade = j.Estadio?.Cidade ?? string.Empty,
        DataHora = j.DataHora,
        TimeA = j.TimeA,
        TimeB = j.TimeB,
        Fase = j.Fase
    };
}
