using System.ComponentModel.DataAnnotations;

namespace MundialTickets.Modelos;

// Entidade de negócio: representa uma linha da tabela Setor (uma área do estádio, com preço base).
public class Setor
{
    public int SetorID { get; set; }

    public int EstadioID { get; set; }

    [Required, StringLength(50)]
    public string NomeSetor { get; set; } = string.Empty;

    // Quantidade de lugares do setor. O banco exige valor maior que zero.
    public int Capacidade { get; set; }

    // Preço de referência do setor; o PrecoFinal de cada Ingresso parte deste valor.
    public decimal PrecoBase { get; set; }

    // Relacionamentos (navegação). O EF Core só os preenche quando a consulta pede (Include).
    public Estadio? Estadio { get; set; }
    public ICollection<Assento> Assentos { get; set; } = new List<Assento>();
}
