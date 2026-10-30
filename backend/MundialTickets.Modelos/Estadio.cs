using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos;

// Entidade de negócio: representa uma linha da tabela Estadio.
// A camada Modelos não referencia nenhum outro projeto da solução —
// ela é a base de tudo e não sabe que existe banco, web ou API.
public class Estadio
{
    public int EstadioID { get; set; }

    // Validações básicas da própria entidade (tamanho, obrigatoriedade).
    // Regras que dependem do banco ficam na camada Negocio, não aqui.
    [Required, StringLength(100)]
    public string Nome { get; set; } = string.Empty;

    [Required, StringLength(100)]
    public string Cidade { get; set; } = string.Empty;

    public int CapacidadeTotal { get; set; }
}
