using System.ComponentModel.DataAnnotations;
using MundialTickets.Modelos.Constantes;

namespace MundialTickets.Modelos;

// Entidade de negócio: representa uma linha da tabela Ingresso (um lugar de um jogo).
public class Ingresso
{
    public int IngressoID { get; set; }

    public int JogoID { get; set; }

    public int SetorID { get; set; }

    // O banco aceita ingresso sem assento (nulo), mas o sistema vende por assento
    // escolhido. O banco não aceita o mesmo assento duas vezes no mesmo jogo.
    public int? AssentoID { get; set; }

    // Cópia do número do assento, gravada junto com o ingresso.
    [StringLength(10)]
    public string? NumeroAssento { get; set; }

    public decimal PrecoFinal { get; set; }

    // Um dos valores de StatusIngresso. A trigger do banco troca para VENDIDO na compra.
    [Required, StringLength(20)]
    public string Status { get; set; } = StatusIngresso.Disponivel;

    // Preenchida pelo banco (default getdate()) quando o ingresso é criado.
    public DateTime DataCriacao { get; set; }

    // Relacionamentos (navegação).
    public Jogo? Jogo { get; set; }
    public Setor? Setor { get; set; }
    public Assento? Assento { get; set; }
}
