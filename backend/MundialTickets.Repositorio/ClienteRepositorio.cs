using System.Data;
using Dapper;
using Microsoft.EntityFrameworkCore;
using MundialTickets.Modelos;
using MundialTickets.Repositorio.Contexto;
using MundialTickets.Repositorio.Interfaces;

namespace MundialTickets.Repositorio;

// Única classe que conversa com a tabela Clientes.
// Exemplo da combinação sugerida no manual:
//   - Entity Framework Core para o cadastro (incluir, consultar, alterar, excluir)
//   - Dapper para a stored procedure
public class ClienteRepositorio : IClienteRepositorio
{
    private readonly AppDbContext _contexto;

    // INJEÇÃO DE DEPENDÊNCIA: o contexto do banco chega pronto, já com a
    // connection string do appsettings.json. Quem monta é a linha AddDbContext
    // do Program.cs. Por isso a connection string não aparece em nenhuma classe.
    public ClienteRepositorio(AppDbContext contexto)
    {
        _contexto = contexto;
    }

    // ---------- Entity Framework Core ----------

    public List<Cliente> Listar() =>
        _contexto.Clientes.AsNoTracking().OrderBy(c => c.Nome).ToList();

    public Cliente? ObterPorId(int id) =>
        _contexto.Clientes.FirstOrDefault(c => c.Id == id);

    public bool EmailEmUso(string email, int? ignorarId = null) =>
        _contexto.Clientes.Any(c => c.Email == email && c.Id != ignorarId);

    public bool CpfEmUso(string cpf, int? ignorarId = null) =>
        _contexto.Clientes.Any(c => c.Cpf == cpf && c.Id != ignorarId);

    public void Adicionar(Cliente cliente)
    {
        _contexto.Clientes.Add(cliente);
        _contexto.SaveChanges();
    }

    public void Atualizar(Cliente cliente)
    {
        _contexto.Clientes.Update(cliente);
        _contexto.SaveChanges();
    }

    public void Remover(Cliente cliente)
    {
        _contexto.Clientes.Remove(cliente);
        _contexto.SaveChanges();
    }

    // ---------- Dapper + stored procedure ----------

    public List<Cliente> BuscarPorNome(string trecho)
    {
        // Reaproveita a mesma conexão (e a mesma connection string) do EF.
        var conexao = _contexto.Database.GetDbConnection();

        // O parâmetro vai separado do comando: isso é o que impede SQL Injection.
        var clientes = conexao.Query<Cliente>(
            "sp_Clientes_BuscarPorNome",
            new { Trecho = trecho },
            commandType: CommandType.StoredProcedure);

        return clientes.ToList();

        // A mesma chamada só com EF Core seria:
        // return _contexto.Clientes
        //     .FromSql($"EXEC sp_Clientes_BuscarPorNome @Trecho = {trecho}")
        //     .ToList();
    }
}
