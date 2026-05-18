using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace classesIngressos
{

    // Classe responsavel por representar um setor dentro de um estadio
    public class Setor
    {
        // Identificador unico do setor
        public int id { get; private set; }

        // Nome do setor, por exemplo: arquibancada, camarote, pista etc.
        public string nome { get; private set; }

        // Cidade relacionada ao setor
        public string cidade { get; private set; }

        // Preco base dos ingressos desse setor
        public decimal preco { get; private set; }

        // Construtor vazio
        public Setor() { }

        // Construtor responsavel por criar um setor com seus dados principais
        public Setor(int id, string nome, string cidade, decimal preco)
        {
            this.id = id;
            this.nome = nome;
            this.cidade = cidade;
            this.preco = preco;
        }
    }
}
