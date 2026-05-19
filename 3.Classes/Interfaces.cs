namespace classesIngressos
{

    // interface usada para definir que uma classe precisa ter uma validacao
    public interface IValidavel
    {
        // metodo que retorna true se os dados forem validos
        // e false se existir alguma informacao incorreta
        bool Validar();
    }

    // interface usada para padronizar as formas de pagamento do sistema
    public interface IMetodoPagamento
    {
        // retorna o nome do metodo de pagamento
        string Nome { get; }

        // processa o pagamento com base no valor recebido
        // retorna true se aprovado e false se nao aprovado
        bool ProcessarPagamento(decimal valor);
    }

    // classe que representa o pagamento via pix
    public class PagamentoPix : IMetodoPagamento
    {
        // nome da forma de pagamento
        public string Nome => "PIX";

        // aprova o pagamento se o valor for maior que zero
        public bool ProcessarPagamento(decimal valor)
        {
            return valor > 0;
        }
    }

    // classe que representa o pagamento via boleto
    public class PagamentoBoleto : IMetodoPagamento
    {
        // nome da forma de pagamento
        public string Nome => "Boleto";

        // retorna false porque o boleto normalmente nao e aprovado na hora
        public bool ProcessarPagamento(decimal valor)
        {
            return false;
        }
    }

    // classe que representa o pagamento via cartao
    public class PagamentoCartao : IMetodoPagamento
    {
        // nome da forma de pagamento
        public string Nome => "Cartao";

        // aprova o pagamento se o valor for maior que zero
        public bool ProcessarPagamento(decimal valor)
        {
            return valor > 0;
        }
    }
}

