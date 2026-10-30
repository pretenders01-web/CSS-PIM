using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos;

// Entidade de negócio: representa uma linha da tabela QRCode (o código de entrada de um ingresso vendido).
// É criada pela trigger do banco quando o item da venda é inserido.
public class QRCode
{
    public int QRCodeID { get; set; }

    public int VendaID { get; set; }

    public int IngressoID { get; set; }

    // Texto do código, único no banco. A imagem do QR é desenhada pelo app, não guardada aqui.
    [Required, StringLength(255)]
    public string CodigoQR { get; set; } = string.Empty;

    // O banco preenche com a data e hora do jogo.
    public DateTime DataExpiracao { get; set; }

    // Marca se o código já foi usado na entrada.
    public bool Utilizado { get; set; }

    // Relacionamentos (navegação).
    public Venda? Venda { get; set; }
    public Ingresso? Ingresso { get; set; }
}
