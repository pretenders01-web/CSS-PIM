using Microsoft.EntityFrameworkCore;
using MundialTickets.Modelos;
using MundialTickets.Repositorio.Contexto;
using MundialTickets.Repositorio.Interfaces;

namespace MundialTickets.Repositorio;

// Única classe que conversa com a tabela Jogo. Acesso por Entity Framework Core.
public class JogoRepositorio : IJogoRepositorio
{
    private readonly AppDbContext _contexto;

    // INJEÇÃO DE DEPENDÊNCIA: o contexto do banco chega pronto, já com a connection string.
    public JogoRepositorio(AppDbContext contexto)
    {
        _contexto = contexto;
    }

    // Include carrega o Estadio junto, para a tela mostrar o nome sem uma segunda consulta.
    public List<Jogo> Listar() =>
        _contexto.Jogos.AsNoTracking()
            .Include(j => j.Estadio)
            .OrderBy(j => j.DataHora)
            .ToList();

    public Jogo? ObterPorId(int id) =>
        _contexto.Jogos.Include(j => j.Estadio).FirstOrDefault(j => j.JogoID == id);

    public bool HorarioOcupado(int estadioId, DateTime dataHora, int? ignorarId = null) =>
        _contexto.Jogos.Any(j => j.EstadioID == estadioId && j.DataHora == dataHora && j.JogoID != ignorarId);

    public bool PossuiIngressos(int id) =>
        _contexto.Ingressos.Any(i => i.JogoID == id);

    public void Adicionar(Jogo jogo)
    {
        _contexto.Jogos.Add(jogo);
        _contexto.SaveChanges();
    }

    public void Atualizar(Jogo jogo)
    {
        _contexto.Jogos.Update(jogo);
        _contexto.SaveChanges();
    }

    public void Remover(Jogo jogo)
    {
        _contexto.Jogos.Remove(jogo);
        _contexto.SaveChanges();
    }
}
