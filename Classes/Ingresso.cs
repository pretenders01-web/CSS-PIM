using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace classesIngressos
{
    // Classe responsavel por representar um ingresso
    public class Ingresso
    {
        // Identificador unico do ingresso
        public int IngressoID { get; private set; }
        // Identificador do jogo relacionado ao ingresso
        public int JogoID { get; private set; }
        // Identificador do setor relacionado ao ingresso
        public int SetorID { get; private set; }
        // Identificador opcional do assento
        // O uso de int? permite que o ingresso exista sem assento definido
        public int? AssentoID { get; private set; }
        // Numero do assento relacionado ao ingresso
        public string NumeroAssento { get; private set; }
        // Valor final do ingresso
        public decimal PrecoFinal { get; private set; }
        // Status do ingresso, por exemplo: disponivel, reservado, vendido ou cancelado
        public string Status { get; private set; }
        // Data em que o ingresso foi criado
        public DateTime DataCriacao { get; private set; }
        // Construtor vazio
        public Ingresso() { }

        // Construtor responsavel por criar um ingresso
        public Ingresso(int ingressoID, int jogoID, int setorID, int? assentoID, string numeroAssento, decimal precoFinal, string status, DateTime dataCriacao)
        {
            IngressoID = ingressoID;
            JogoID = jogoID;
            SetorID = setorID;
            AssentoID = assentoID;
            NumeroAssento = numeroAssento;
            PrecoFinal = precoFinal;
            Status = status;
            DataCriacao = dataCriacao;
        }
    }
}
