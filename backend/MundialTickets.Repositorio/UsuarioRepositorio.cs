using Microsoft.EntityFrameworkCore;
using MundialTickets.Modelos;
using MundialTickets.Repositorio.Contexto;
using MundialTickets.Repositorio.Interfaces;

namespace MundialTickets.Repositorio;

// Única classe que conversa com a tabela Usuario. Acesso por Entity Framework Core.
public class UsuarioRepositorio : IUsuarioRepositorio
{
    private readonly AppDbContext _contexto;

    // INJEÇÃO DE DEPENDÊNCIA: o contexto do banco chega pronto, já com a connection string.
    public UsuarioRepositorio(AppDbContext contexto)
    {
        _contexto = contexto;
    }

    public Usuario? ObterPorId(int id) =>
        _contexto.Usuarios.FirstOrDefault(u => u.UsuarioID == id);

    public Usuario? ObterPorEmail(string email) =>
        _contexto.Usuarios.FirstOrDefault(u => u.Email == email);

    public bool EmailEmUso(string email, int? ignorarId = null) =>
        _contexto.Usuarios.Any(u => u.Email == email && u.UsuarioID != ignorarId);

    public void Adicionar(Usuario usuario)
    {
        _contexto.Usuarios.Add(usuario);
        _contexto.SaveChanges();
    }

    public void Atualizar(Usuario usuario)
    {
        _contexto.Usuarios.Update(usuario);
        _contexto.SaveChanges();
    }

    // Um UPDATE direto no banco, sem carregar o usuário: só troca a coluna Ativo.
    public bool Desativar(int id) =>
        _contexto.Usuarios
            .Where(u => u.UsuarioID == id)
            .ExecuteUpdate(s => s.SetProperty(u => u.Ativo, false)) > 0;
}
