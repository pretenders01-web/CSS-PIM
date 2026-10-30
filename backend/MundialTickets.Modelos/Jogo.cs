using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos;

// Entidade de negócio: representa uma linha da tabela Jogo.
public class Jogo
{
    public int JogoID { get; set; }

    public int EstadioID { get; set; }

    // Data e hora da partida. O banco não aceita dois jogos no mesmo estádio e horário.
    public DateTime DataHora { get; set; }

    [Required, StringLength(50)]
    public string TimeA { get; set; } = string.Empty;

    [Required, StringLength(50)]
    public string TimeB { get; set; } = string.Empty;

    [Required, StringLength(30)]
    public string Fase { get; set; } = string.Empty;

    // Relacionamento (navegação).
    public Estadio? Estadio { get; set; }
}
