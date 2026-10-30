using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de SAÍDA do comprador: um assento disponível de um setor, já ligado ao ingresso
// que será comprado. O comprador marca assentos e a compra envia os IngressoId.
public class AssentoDisponivelDto
{
    public int IngressoId { get; set; }

    public int AssentoId { get; set; }

    [Display(Name = "Assento")]
    public string Numero { get; set; } = string.Empty;

    [Display(Name = "Preço")]
    public decimal Preco { get; set; }
}
