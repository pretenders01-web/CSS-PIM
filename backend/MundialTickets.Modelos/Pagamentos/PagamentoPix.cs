namespace MundialTickets.Modelos.Pagamentos;

// Pagamento via Pix (simulado): usa a regra padrão da classe base.
public class PagamentoPix : MetodoPagamentoBase
{
    public override string Nome => "PIX";
}
