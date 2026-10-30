using MundialTickets.Modelos;

namespace MundialTickets.Repositorio.Interfaces;

public interface IJogoRepositorio
{
    // Os jogos já vêm com o Estadio carregado, ordenados por data e hora.
    List<Jogo> Listar();
    Jogo? ObterPorId(int id);

    // True se já existe outro jogo no mesmo estádio e horário.
    bool HorarioOcupado(int estadioId, DateTime dataHora, int? ignorarId = null);

    // True quando o jogo já tem ingressos.
    bool PossuiIngressos(int id);

    void Adicionar(Jogo jogo);
    void Atualizar(Jogo jogo);
    void Remover(Jogo jogo);
}
