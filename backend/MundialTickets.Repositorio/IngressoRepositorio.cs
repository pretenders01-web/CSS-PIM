using Microsoft.EntityFrameworkCore;
using MundialTickets.Modelos;
using MundialTickets.Modelos.Constantes;
using MundialTickets.Repositorio.Contexto;
using MundialTickets.Repositorio.Interfaces;

namespace MundialTickets.Repositorio;

// Única classe que conversa com a tabela Ingresso. Acesso por Entity Framework Core.
// A troca do status para VENDIDO na compra é feita pela trigger do banco, não por esta classe.
public class IngressoRepositorio : IIngressoRepositorio
{
    private readonly AppDbContext _contexto;

    // INJEÇÃO DE DEPENDÊNCIA: o contexto do banco chega pronto, já com a connection string.
    public IngressoRepositorio(AppDbContext contexto)
    {
        _contexto = contexto;
    }

    public List<Ingresso> Listar(int? jogoId = null, string? status = null)
    {
        var consulta = _contexto.Ingressos.AsNoTracking()
            .Include(i => i.Jogo)
            .Include(i => i.Setor)
            .Include(i => i.Assento)
            .AsQueryable();

        if (jogoId.HasValue) consulta = consulta.Where(i => i.JogoID == jogoId.Value);
        if (!string.IsNullOrWhiteSpace(status)) consulta = consulta.Where(i => i.Status == status);

        return consulta
            .OrderBy(i => i.JogoID).ThenBy(i => i.SetorID).ThenBy(i => i.NumeroAssento)
            .ToList();
    }

    public Ingresso? ObterPorId(int id) =>
        _contexto.Ingressos
            .Include(i => i.Jogo)
            .Include(i => i.Setor)
            .Include(i => i.Assento)
            .FirstOrDefault(i => i.IngressoID == id);

    // O EF transforma o Contains em IN (@p0, @p1...): os ids vão como parâmetros.
    public List<Ingresso> ObterPorIds(IEnumerable<int> ids)
    {
        var lista = ids.Distinct().ToList();
        return _contexto.Ingressos.AsNoTracking()
            .Include(i => i.Jogo)
            .Include(i => i.Setor)
            .Include(i => i.Assento)
            .Where(i => lista.Contains(i.IngressoID))
            .ToList();
    }

    public List<Ingresso> ListarDisponiveis(int jogoId, int setorId) =>
        _contexto.Ingressos.AsNoTracking()
            .Include(i => i.Assento)
            .Where(i => i.JogoID == jogoId
                     && i.SetorID == setorId
                     && i.Status == StatusIngresso.Disponivel
                     && i.AssentoID != null)
            .OrderBy(i => i.NumeroAssento)
            .ToList();

    public Dictionary<int, int> ContarDisponiveisPorSetor(int jogoId) =>
        _contexto.Ingressos.AsNoTracking()
            .Where(i => i.JogoID == jogoId
                     && i.Status == StatusIngresso.Disponivel
                     && i.AssentoID != null)
            .GroupBy(i => i.SetorID)
            .Select(g => new { SetorId = g.Key, Quantidade = g.Count() })
            .ToDictionary(x => x.SetorId, x => x.Quantidade);

    public bool ExisteParaAssento(int jogoId, int setorId, int assentoId, int? ignorarId = null) =>
        _contexto.Ingressos.Any(i => i.JogoID == jogoId
                                  && i.SetorID == setorId
                                  && i.AssentoID == assentoId
                                  && i.IngressoID != ignorarId);

    public List<int> ListarAssentoIdsComIngresso(int jogoId) =>
        _contexto.Ingressos.AsNoTracking()
            .Where(i => i.JogoID == jogoId && i.AssentoID != null)
            .Select(i => i.AssentoID!.Value)
            .ToList();

    public bool PossuiVenda(int id) =>
        _contexto.ItensVenda.Any(v => v.IngressoID == id);

    public void Adicionar(Ingresso ingresso)
    {
        _contexto.Ingressos.Add(ingresso);
        _contexto.SaveChanges();
    }

    // Um único SaveChanges grava tudo na mesma transação: se um falhar, nenhum entra.
    public void AdicionarVarios(IEnumerable<Ingresso> ingressos)
    {
        _contexto.Ingressos.AddRange(ingressos);
        _contexto.SaveChanges();
    }

    public void Atualizar(Ingresso ingresso)
    {
        _contexto.Ingressos.Update(ingresso);
        _contexto.SaveChanges();
    }

    public void Remover(Ingresso ingresso)
    {
        _contexto.Ingressos.Remove(ingresso);
        _contexto.SaveChanges();
    }
}
