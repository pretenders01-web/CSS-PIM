using MundialTickets.Modelos;
using MundialTickets.Repositorio.Interfaces;

namespace MundialTickets.Negocio;

// Regras do jogo. Web e Api chamam esta classe; esta classe chama o repositório.
// O sistema lista e vende todos os jogos, sem filtrar por data (as datas do seed já passaram).
public class JogoNegocio
{
    private readonly IJogoRepositorio _jogos;
    private readonly IEstadioRepositorio _estadios;

    // INJEÇÃO DE DEPENDÊNCIA: os repositórios chegam prontos no construtor.
    public JogoNegocio(IJogoRepositorio jogos, IEstadioRepositorio estadios)
    {
        _jogos = jogos;
        _estadios = estadios;
    }

    // Já vêm com o Estadio carregado, ordenados por data e hora.
    public List<Jogo> Listar() => _jogos.Listar();

    public Jogo? ObterPorId(int id) => _jogos.ObterPorId(id);

    public Jogo Cadastrar(Jogo jogo)
    {
        Normalizar(jogo);
        Validar(jogo, ignorarId: null);

        _jogos.Adicionar(jogo);
        return jogo;
    }

    public void Atualizar(Jogo jogo)
    {
        var existente = _jogos.ObterPorId(jogo.JogoID)
            ?? throw new RegraDeNegocioException("Jogo não encontrado.");

        Normalizar(jogo);
        Validar(jogo, ignorarId: jogo.JogoID);

        existente.EstadioID = jogo.EstadioID;
        existente.DataHora = jogo.DataHora;
        existente.TimeA = jogo.TimeA;
        existente.TimeB = jogo.TimeB;
        existente.Fase = jogo.Fase;

        _jogos.Atualizar(existente);
    }

    // Devolve false quando o jogo não existe.
    // Lança RegraDeNegocioException se ele já tem ingressos.
    public bool Remover(int id)
    {
        var jogo = _jogos.ObterPorId(id);
        if (jogo is null) return false;

        if (_jogos.PossuiIngressos(id))
            throw new RegraDeNegocioException("Não é possível excluir um jogo que já tem ingressos.");

        _jogos.Remover(jogo);
        return true;
    }

    // ---------- regras ----------

    private static void Normalizar(Jogo jogo)
    {
        jogo.TimeA = (jogo.TimeA ?? string.Empty).Trim();
        jogo.TimeB = (jogo.TimeB ?? string.Empty).Trim();
        jogo.Fase = (jogo.Fase ?? string.Empty).Trim();
    }

    private void Validar(Jogo jogo, int? ignorarId)
    {
        if (_estadios.ObterPorId(jogo.EstadioID) is null)
            throw new RegraDeNegocioException("Estádio não encontrado.");

        if (string.Equals(jogo.TimeA, jogo.TimeB, StringComparison.OrdinalIgnoreCase))
            throw new RegraDeNegocioException("Os dois times devem ser diferentes.");

        if (_jogos.HorarioOcupado(jogo.EstadioID, jogo.DataHora, ignorarId))
            throw new RegraDeNegocioException("Já existe um jogo neste estádio neste horário.");
    }
}
