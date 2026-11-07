using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de SAÍDA de "Meus ingressos": um ingresso já comprado, com o código do QR.
// Vem de uma consulta que junta Venda, ItemVenda, QRCode, Jogo, Estadio, Setor e Assento.
public class IngressoCompradoDto
{
    public int IngressoId { get; set; }

    public int VendaId { get; set; }

    [Display(Name = "Partida")]
    public string Partida { get; set; } = string.Empty;

    // Os times separados, para o app mostrar a bandeira de cada um.
    [Display(Name = "Time A")]
    public string TimeA { get; set; } = string.Empty;

    [Display(Name = "Time B")]
    public string TimeB { get; set; } = string.Empty;

    [Display(Name = "Data do jogo")]
    public DateTime DataJogo { get; set; }

    // Nome e cidade do estádio, para o cartão do app e o botão "Como chegar".
    [Display(Name = "Estádio")]
    public string EstadioNome { get; set; } = string.Empty;

    [Display(Name = "Cidade")]
    public string EstadioCidade { get; set; } = string.Empty;

    [Display(Name = "Setor")]
    public string NomeSetor { get; set; } = string.Empty;

    [Display(Name = "Assento")]
    public string? NumeroAssento { get; set; }

    [Display(Name = "Preço pago")]
    public decimal PrecoPago { get; set; }

    // Texto do código. A imagem do QR é desenhada pelo app (Flutter), não guardada aqui.
    [Display(Name = "Código do QR")]
    public string CodigoQR { get; set; } = string.Empty;

    // Cópia da data do jogo feita na venda, que pode ficar velha se a data do jogo mudar.
    // Quem decide se o ingresso ainda vale é DataJogo (a data atual do jogo).
    [Display(Name = "Válido até")]
    public DateTime DataExpiracao { get; set; }

    [Display(Name = "Utilizado")]
    public bool Utilizado { get; set; }
}
