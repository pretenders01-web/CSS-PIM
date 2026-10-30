using Microsoft.EntityFrameworkCore;
using MundialTickets.Modelos;
using MundialTickets.Repositorio.Contexto;
using MundialTickets.Repositorio.Interfaces;

namespace MundialTickets.Repositorio;

// Única classe que conversa com a tabela Setor. Acesso por Entity Framework Core.
public class SetorRepositorio : ISetorRepositorio
{
    private readonly AppDbContext _contexto;

    // INJEÇÃO DE DEPENDÊNCIA: o contexto do banco chega pronto, já com a connection string.
    public SetorRepositorio(AppDbContext contexto)
    {
        _contexto = contexto;
    }

    public List<Setor> Listar() =>
        _contexto.Setores.AsNoTracking().OrderBy(s => s.EstadioID).ThenBy(s => s.NomeSetor).ToList();

    public List<Setor> ListarPorEstadio(int estadioId) =>
        _contexto.Setores.AsNoTracking()
            .Where(s => s.EstadioID == estadioId)
            .OrderBy(s => s.NomeSetor)
            .ToList();

    public Setor? ObterPorId(int id) =>
        _contexto.Setores.FirstOrDefault(s => s.SetorID == id);

    public bool NomeEmUsoNoEstadio(int estadioId, string nomeSetor, int? ignorarId = null) =>
        _contexto.Setores.Any(s => s.EstadioID == estadioId && s.NomeSetor == nomeSetor && s.SetorID != ignorarId);

    public int SomaCapacidadeDoEstadio(int estadioId, int? ignorarId = null) =>
        _contexto.Setores
            .Where(s => s.EstadioID == estadioId && s.SetorID != ignorarId)
            .Sum(s => s.Capacidade);

    public bool PossuiVinculos(int id) =>
        _contexto.Assentos.Any(a => a.SetorID == id)
        || _contexto.Ingressos.Any(i => i.SetorID == id);

    public void Adicionar(Setor setor)
    {
        _contexto.Setores.Add(setor);
        _contexto.SaveChanges();
    }

    public void Atualizar(Setor setor)
    {
        _contexto.Setores.Update(setor);
        _contexto.SaveChanges();
    }

    public void Remover(Setor setor)
    {
        _contexto.Setores.Remove(setor);
        _contexto.SaveChanges();
    }
}
