using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace classesIngressos
{

    // Classe responsavel por representar uma venda realizada no sistema
    public class Venda
    {
        // Identificador unico da venda
        public int VendaID { get; private set; }

        // Identificador do usuario que realizou a compra
        public int UsuarioID { get; private set; }

        // Data em que a venda foi realizada
        public DateTime DataVenda { get; private set; }

        // Valor total da venda
        public decimal ValorTotal { get; private set; }

        // Status do pagamento, por exemplo: pendente, pago ou cancelado
        public string StatusPagamento { get; private set; }

        // Metodo de pagamento utilizado, por exemplo: PIX, cartao ou boleto
        public string MetodoPagamento { get; private set; }

        // Construtor vazio
        public Venda() { }

        // Construtor responsavel por criar uma venda
        public Venda(int vendaID, int usuarioID, DateTime dataVenda, decimal valorTotal, string statusPagamento, string metodoPagamento)
        {
            VendaID = vendaID;
            UsuarioID = usuarioID;
            DataVenda = dataVenda;
            ValorTotal = valorTotal;
            StatusPagamento = statusPagamento;
            MetodoPagamento = metodoPagamento;
        }

        public void Pagar(IMetodoPagamento metodoPagamento)
        {
            // armazena na venda o nome do metodo de pagamento utilizado
            // exemplo: se o objeto recebido for PagamentoPix, o valor salvo sera "PIX"
            // se for PagamentoCartao, o valor salvo sera "Cartao"
            MetodoPagamento = metodoPagamento.Nome;

            // chama o metodo ProcessarPagamento da forma de pagamento recebida
            // O valor total da venda e enviado como parametro
            // esse metodo retorna true se o pagamento for aprovado
            // ou false se o pagamento nao for aprovado no momento
            bool aprovado = metodoPagamento.ProcessarPagamento(ValorTotal);

            // verifica se o pagamento foi aprovado
            // se aprovado for true significa que o pagamento foi confirmado
            if (aprovado)
            {
                // Atualiza o status da venda para "Pago".
                StatusPagamento = "Pago";
            }
            else
            {
                // Caso o pagamento nao tenha sido aprovado,
                // a venda continua com status "Pendente".
                // Isso pode acontecer, por exemplo, em pagamentos por boleto.
                StatusPagamento = "Pendente";
            }
        }
    }
}
