using Microsoft.EntityFrameworkCore;
using MundialTickets.Modelos;
using MundialTickets.Repositorio.Contexto;
using MundialTickets.Repositorio.Interfaces;

namespace MundialTickets.Repositorio;

// Única classe que conversa com a tabela Estadio.
// Aqui o acesso é todo por Entity Framework Core; o Dapper entra na stored
// procedure de compra (sp_RealizarCompra), no repositório de vendas.
public class EstadioRepositorio : IEstadioRepositorio
{
    private readonly AppDbContext _contexto;

    // INJEÇÃO DE DEPENDÊNCIA: o contexto do banco chega pronto, já com a
    // connection string do appsettings.json. Quem monta é a linha AddDbContext
    // do Program.cs. Por isso a connection string não aparece em nenhuma classe.
    public EstadioRepositorio(AppDbContext contexto)
    {
        _contexto = contexto;
    }

    public List<Estadio> Listar() =>
        _contexto.Estadios.AsNoTracking().OrderBy(e => e.Nome).ToList();

    public Estadio? ObterPorId(int id) =>
        _contexto.Estadios.FirstOrDefault(e => e.EstadioID == id);

    public bool NomeEmUsoNaCidade(string nome, string cidade, int? ignorarId = null) =>
        _contexto.Estadios.Any(e => e.Nome == nome && e.Cidade == cidade && e.EstadioID != ignorarId);

    // Consulta parametrizada: o id vai como parâmetro, nunca concatenado no SQL.
    public bool PossuiVinculos(int id) =>
        _contexto.Database
            .SqlQuery<int>($"SELECT (SELECT COUNT(*) FROM Setor WHERE EstadioID = {id}) + (SELECT COUNT(*) FROM Jogo WHERE EstadioID = {id}) AS Value")
            .AsEnumerable()
            .First() > 0;

    public void Adicionar(Estadio estadio)
    {
        _contexto.Estadios.Add(estadio);
        _contexto.SaveChanges();
    }

    public void Atualizar(Estadio estadio)
    {
        _contexto.Estadios.Update(estadio);
        _contexto.SaveChanges();
    }

    public void Remover(Estadio estadio)
    {
        _contexto.Estadios.Remove(estadio);
        _contexto.SaveChanges();
    }
}
