using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de SAÍDA do comprador: um setor de um jogo, com o preço e quantos assentos
// ainda estão disponíveis. É o que o comprador vê ao escolher o setor.
public class SetorDisponibilidadeDto
{
    public int SetorId { get; set; }

    [Display(Name = "Setor")]
    public string NomeSetor { get; set; } = string.Empty;

    [Display(Name = "Preço")]
    public decimal PrecoBase { get; set; }

    [Display(Name = "Assentos disponíveis")]
    public int AssentosDisponiveis { get; set; }
}
