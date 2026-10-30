using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos.Dtos;

// DTO de SAÍDA da compra. As três propriedades têm o MESMO NOME das colunas que a stored
// procedure sp_RealizarCompra devolve (CodigoQR, DataJogo, Partida), para o Dapper
// preencher este objeto direto do resultado.
public class CompraResultadoDto
{
    [Display(Name = "Código do QR")]
    public string CodigoQR { get; set; } = string.Empty;

    [Display(Name = "Data do jogo")]
    public DateTime DataJogo { get; set; }

    [Display(Name = "Partida")]
    public string Partida { get; set; } = string.Empty;
}
