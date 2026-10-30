namespace MundialTickets.Modelos.Pagamentos;

// Classe base abstrata das formas de pagamento (herança).
// Cada forma só diz o seu nome; a regra padrão de aprovação fica aqui e pode ser
// trocada por quem herda (sobrescrita), como faz o boleto.
public abstract class MetodoPagamentoBase : IMetodoPagamento
{
    public abstract string Nome { get; }

    // Regra padrão da simulação: aprova qualquer valor maior que zero.
    public virtual bool ProcessarPagamento(decimal valor) => valor > 0;
}
