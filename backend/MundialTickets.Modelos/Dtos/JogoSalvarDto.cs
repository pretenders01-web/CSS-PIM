using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de ENTRADA: o que o administrador PREENCHE para cadastrar ou alterar um jogo.
// As regras que dependem do banco (estádio existente, horário livre no estádio) ficam no Negocio.
public class JogoSalvarDto
{
    [Display(Name = "Estádio")]
    [Range(1, int.MaxValue, ErrorMessage = "Escolha o estádio.")]
    public int EstadioID { get; set; }

    [Display(Name = "Data e hora")]
    [Required(ErrorMessage = "Informe a data e a hora.")]
    public DateTime DataHora { get; set; }

    [Display(Name = "Time A")]
    [Required(ErrorMessage = "Informe o time A.")]
    [StringLength(50, ErrorMessage = "O nome do time pode ter no máximo 50 caracteres.")]
    public string TimeA { get; set; } = string.Empty;

    [Display(Name = "Time B")]
    [Required(ErrorMessage = "Informe o time B.")]
    [StringLength(50, ErrorMessage = "O nome do time pode ter no máximo 50 caracteres.")]
    public string TimeB { get; set; } = string.Empty;

    [Display(Name = "Fase")]
    [Required(ErrorMessage = "Informe a fase.")]
    [StringLength(30, ErrorMessage = "A fase pode ter no máximo 30 caracteres.")]
    public string Fase { get; set; } = string.Empty;

    public Jogo ParaJogo(int id = 0) => new()
    {
        JogoID = id,
        EstadioID = EstadioID,
        DataHora = DataHora,
        TimeA = TimeA,
        TimeB = TimeB,
        Fase = Fase
    };

    public static JogoSalvarDto De(Jogo j) => new()
    {
        EstadioID = j.EstadioID,
        DataHora = j.DataHora,
        TimeA = j.TimeA,
        TimeB = j.TimeB,
        Fase = j.Fase
    };
}
