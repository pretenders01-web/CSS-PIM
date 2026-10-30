using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de ENTRADA da compra (tela de Pagamento e POST /api/vendas).
// Não tem UsuarioID: o comprador é sempre quem está logado, lido do cookie ou do token.
public class CompraPedidoDto
{
    [Display(Name = "Ingressos")]
    [Required(ErrorMessage = "Escolha ao menos um ingresso.")]
    [MinLength(1, ErrorMessage = "Escolha ao menos um ingresso.")]
    public List<int> IngressoIds { get; set; } = new();

    // PIX, Cartao ou Boleto. O Negocio recusa um nome que não conhece.
    [Display(Name = "Forma de pagamento")]
    [Required(ErrorMessage = "Escolha a forma de pagamento.")]
    public string MetodoPagamento { get; set; } = string.Empty;
}
