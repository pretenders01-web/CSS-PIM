namespace MundialTickets.Modelos.Pagamentos;

// Pagamento com cartão (simulado): usa a regra padrão da classe base.
public class PagamentoCartao : MetodoPagamentoBase
{
    public override string Nome => "Cartao";
}
