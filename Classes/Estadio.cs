using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace classesIngressos
{
    // Classe responsavel por representar um estadio
    public class Estadio
    {
        // Identificador unico do estadio
        public int Id { get; private set; }

        // Nome do estadio
        public string Nome { get; private set; }

        // Cidade onde o estadio esta localizado
        public string Cidade { get; private set; }

        // Capacidade total de publico do estadio
        public int CapacidadeTotal { get; private set; }

        // Construtor vazio
        public Estadio() { }

        // Construtor responsavel por criar um estadio com seus dados principais
        public Estadio(int id, string nome, string cidade, int capacidadeTotal)
        {
            Id = id;
            Nome = nome;
            Cidade = cidade;
            CapacidadeTotal = capacidadeTotal;
        }
    }
}
