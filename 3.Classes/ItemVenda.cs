using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace classesIngressos
{
    // Classe responsavel por representar um item dentro de uma venda
    public class ItemVenda
    {
        // Identificador unico do item da venda
        public int ItemVendaID { get; private set; }

        // Identificador da venda a qual o item pertence
        public int VendaID { get; private set; }

        // Identificador do ingresso vendido
        public int IngressoID { get; private set; }

        // Preco unitario do ingresso no momento da venda
        public decimal PrecoUnitario { get; private set; }

        // Construtor vazio
        public ItemVenda() { }

        // Construtor responsavel por criar um item de venda
        public ItemVenda(int itemVendaID, int vendaID, int ingressoID, decimal precoUnitario)
        {
            ItemVendaID = itemVendaID;
            VendaID = vendaID;
            IngressoID = ingressoID;
            PrecoUnitario = precoUnitario;
        }
    }
}
