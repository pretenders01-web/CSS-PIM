using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace classesIngressos
{
    // Classe responsavel por representar um jogo ou partida
    public class Jogo
    {
        // Identificador unico do jogo
        public int JogoID { get; private set; }
        // Identificador do estadio onde o jogo sera realizado
        public int EstadioID { get; private set; }
        // Data e horario do jogo
        public DateTime DataHora { get; private set; }
        // Nome da primeira equipe
        public string TimeA { get; private set; }
        // Nome da segunda equipe
        public string TimeB { get; private set; }
        // Fase da competicao, por exemplo: grupos, oitavas, semifinal, final
        public string Fase { get; private set; }

        // Construtor vazio
        public Jogo() { }
        // Construtor responsavel por criar um jogo
        public Jogo(int jogoID, int estadioID, DateTime dataHora, string timeA, string timeB, string fase)
        {
            JogoID = jogoID;
            EstadioID = estadioID;
            DataHora = dataHora;
            TimeA = timeA;
            TimeB = timeB;
            Fase = fase;
        }
    }
}
