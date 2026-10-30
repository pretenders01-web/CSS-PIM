using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de SAÍDA: o que o sistema MOSTRA de um assento.
public class AssentoDto
{
    public int Id { get; set; }

    public int SetorId { get; set; }

    [Display(Name = "Número")]
    public string Numero { get; set; } = string.Empty;

    public static AssentoDto De(Assento a) => new()
    {
        Id = a.AssentoID,
        SetorId = a.SetorID,
        Numero = a.Numero
    };
}
