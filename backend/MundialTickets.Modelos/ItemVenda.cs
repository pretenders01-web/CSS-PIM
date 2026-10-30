namespace MundialTickets.Modelos;

// Entidade de negócio: representa uma linha da tabela ItemVenda (um ingresso dentro de uma venda).
// Um ingresso só pode estar em uma venda (o banco tem índice único em IngressoID).
public class ItemVenda
{
    public int ItemVendaID { get; set; }

    public int VendaID { get; set; }

    public int IngressoID { get; set; }

    // Preço do ingresso no momento da compra (copiado de Ingresso.PrecoFinal).
    public decimal PrecoUnitario { get; set; }

    // Relacionamentos (navegação).
    public Venda? Venda { get; set; }
    public Ingresso? Ingresso { get; set; }
}
