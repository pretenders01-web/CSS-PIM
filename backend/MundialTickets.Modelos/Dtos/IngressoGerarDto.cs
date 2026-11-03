using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de ENTRADA da geração de ingressos em lote (POST /api/ingressos/gerar e o botão
// "gerar para um jogo" da página de Ingresso): basta dizer o jogo.
public class IngressoGerarDto
{
    [Display(Name = "Jogo")]
    [Range(1, int.MaxValue, ErrorMessage = "Escolha o jogo.")]
    public int JogoID { get; set; }
}
