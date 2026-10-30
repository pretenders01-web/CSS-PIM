using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos;

// Entidade de negócio: representa uma linha da tabela Assento (um lugar numerado de um setor).
public class Assento
{
    public int AssentoID { get; set; }

    public int SetorID { get; set; }

    // Identificação do lugar dentro do setor (por exemplo, A01). Único por setor no banco.
    [Required, StringLength(10)]
    public string Numero { get; set; } = string.Empty;

    // Relacionamento (navegação).
    public Setor? Setor { get; set; }
}
