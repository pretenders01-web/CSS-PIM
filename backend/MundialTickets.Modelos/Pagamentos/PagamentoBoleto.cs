namespace MundialTickets.Modelos.Pagamentos;

// Pagamento por boleto (simulado): não é aprovado na hora, então sobrescreve a regra
// padrão da classe base e devolve sempre false.
public class PagamentoBoleto : MetodoPagamentoBase
{
    public override string Nome => "Boleto";

    public override bool ProcessarPagamento(decimal valor) => false;
}
