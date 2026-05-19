using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace classesIngressos
{
    // Classe responsavel por representar um assento especifico dentro de um setor
    public class Assento
    {
        // Identificador unico do assento
        public int AssentoID { get; private set; }

        // Identificador do setor ao qual o assento pertence
        public int SetorID { get; private set; }

        // Numero ou codigo do assento
        public string Numero { get; private set; }

        // Construtor vazio
        public Assento() { }

        // Construtor responsavel por criar um assento
        public Assento(int assentoID, int setorID, string numero)
        {
            AssentoID = assentoID;
            SetorID = setorID;
            Numero = numero;
        }
    }
}
