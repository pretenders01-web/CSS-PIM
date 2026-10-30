using Microsoft.EntityFrameworkCore;
using MundialTickets.Modelos;
using MundialTickets.Repositorio.Contexto;
using MundialTickets.Repositorio.Interfaces;

namespace MundialTickets.Repositorio;

// Única classe que conversa com a tabela Assento. Acesso por Entity Framework Core.
public class AssentoRepositorio : IAssentoRepositorio
{
    private readonly AppDbContext _contexto;

    // INJEÇÃO DE DEPENDÊNCIA: o contexto do banco chega pronto, já com a connection string.
    public AssentoRepositorio(AppDbContext contexto)
    {
        _contexto = contexto;
    }

    public List<Assento> ListarPorSetor(int setorId) =>
        _contexto.Assentos.AsNoTracking()
            .Where(a => a.SetorID == setorId)
            .OrderBy(a => a.Numero)
            .ToList();

    public Assento? ObterPorId(int id) =>
        _contexto.Assentos.FirstOrDefault(a => a.AssentoID == id);

    public bool NumeroEmUsoNoSetor(int setorId, string numero, int? ignorarId = null) =>
        _contexto.Assentos.Any(a => a.SetorID == setorId && a.Numero == numero && a.AssentoID != ignorarId);

    public int ContarPorSetor(int setorId) =>
        _contexto.Assentos.Count(a => a.SetorID == setorId);

    public List<string> ListarNumerosDoSetor(int setorId) =>
        _contexto.Assentos.AsNoTracking()
            .Where(a => a.SetorID == setorId)
            .Select(a => a.Numero)
            .ToList();

    public bool PossuiIngresso(int id) =>
        _contexto.Ingressos.Any(i => i.AssentoID == id);

    public void Adicionar(Assento assento)
    {
        _contexto.Assentos.Add(assento);
        _contexto.SaveChanges();
    }

    // Um único SaveChanges grava tudo na mesma transação: se um falhar, nenhum entra.
    public void AdicionarVarios(IEnumerable<Assento> assentos)
    {
        _contexto.Assentos.AddRange(assentos);
        _contexto.SaveChanges();
    }

    public void Atualizar(Assento assento)
    {
        _contexto.Assentos.Update(assento);
        _contexto.SaveChanges();
    }

    public void Remover(Assento assento)
    {
        _contexto.Assentos.Remove(assento);
        _contexto.SaveChanges();
    }
}
