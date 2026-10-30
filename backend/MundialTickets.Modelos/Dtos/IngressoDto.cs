using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de SAÍDA: o que o sistema MOSTRA de um ingresso (telas e JSON da Api).
public class IngressoDto
{
    public int Id { get; set; }

    public int JogoId { get; set; }

    public int SetorId { get; set; }

    [Display(Name = "Setor")]
    public string NomeSetor { get; set; } = string.Empty;

    public int? AssentoId { get; set; }

    [Display(Name = "Assento")]
    public string? NumeroAssento { get; set; }

    [Display(Name = "Preço")]
    public decimal PrecoFinal { get; set; }

    [Display(Name = "Situação")]
    public string Status { get; set; } = string.Empty;

    [Display(Name = "Criado em")]
    public DateTime DataCriacao { get; set; }

    // O setor só vem preenchido quando a consulta pediu (Include); sem ele, o nome fica vazio.
    public static IngressoDto De(Ingresso i) => new()
    {
        Id = i.IngressoID,
        JogoId = i.JogoID,
        SetorId = i.SetorID,
        NomeSetor = i.Setor?.NomeSetor ?? string.Empty,
        AssentoId = i.AssentoID,
        NumeroAssento = i.NumeroAssento,
        PrecoFinal = i.PrecoFinal,
        Status = i.Status,
        DataCriacao = i.DataCriacao
    };
}
