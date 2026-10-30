using System.ComponentModel.DataAnnotations;
using MundialTickets.Modelos.Constantes;

namespace MundialTickets.Modelos;

// Entidade de negócio: representa uma linha da tabela Venda (uma compra de um usuário).
// A venda é criada pela stored procedure sp_RealizarCompra, não por gravação direta do EF Core.
public class Venda
{
    public int VendaID { get; set; }

    public int UsuarioID { get; set; }

    // Preenchida pelo banco (default getdate()).
    public DateTime DataVenda { get; set; }

    // Recalculado pela trigger do banco como a soma dos itens.
    public decimal ValorTotal { get; set; }

    // Um dos valores de StatusPagamento.
    [Required, StringLength(20)]
    public string StatusPagamento { get; set; } = Constantes.StatusPagamento.Pendente;

    // Nome da forma de pagamento usada (PIX, Cartao ou Boleto). Opcional no banco.
    [StringLength(30)]
    public string? MetodoPagamento { get; set; }

    // Relacionamentos (navegação).
    public Usuario? Usuario { get; set; }
    public ICollection<ItemVenda> Itens { get; set; } = new List<ItemVenda>();
}
