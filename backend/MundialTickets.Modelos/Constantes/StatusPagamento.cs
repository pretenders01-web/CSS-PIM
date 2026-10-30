namespace MundialTickets.Modelos.Constantes;

// Valores aceitos pela coluna Venda.StatusPagamento (restrição CHECK do banco).
public static class StatusPagamento
{
    public const string Pendente = "PENDENTE";
    public const string Aprovado = "APROVADO";
    public const string Cancelado = "CANCELADO";
    public const string Estornado = "ESTORNADO";
}
