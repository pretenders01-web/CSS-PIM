using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de ENTRADA da alteração de preço de um ingresso (PUT /api/ingressos/{id}/preco).
// O preço é a única coisa que se altera em um ingresso, e só enquanto ele está disponível.
public class IngressoPrecoDto
{
    // A coluna é decimal(10,2): no máximo 99.999.999,99.
    [Display(Name = "Preço")]
    [Range(0.01, 99999999.99, ErrorMessage = "O preço deve estar entre 0,01 e 99.999.999,99.")]
    public decimal PrecoFinal { get; set; }
}
