namespace MundialTickets.Modelos.Pagamentos;

// Contrato das formas de pagamento do sistema. O Negócio trabalha só com este contrato:
// não precisa saber se é Pix, cartão ou boleto (polimorfismo).
// O pagamento é uma SIMULAÇÃO: nenhuma forma chama serviço externo.
public interface IMetodoPagamento
{
    // Nome gravado em Venda.MetodoPagamento.
    string Nome { get; }

    // Processa o pagamento do valor informado.
    // Devolve true se aprovado na hora e false se não aprovado.
    bool ProcessarPagamento(decimal valor);
}
