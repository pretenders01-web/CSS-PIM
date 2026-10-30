using MundialTickets.Modelos;

namespace MundialTickets.Repositorio.Interfaces;

public interface IUsuarioRepositorio
{
    Usuario? ObterPorId(int id);
    Usuario? ObterPorEmail(string email);
    bool EmailEmUso(string email, int? ignorarId = null);

    void Adicionar(Usuario usuario);
    void Atualizar(Usuario usuario);

    // Desativa a conta (Ativo = 0) sem apagá-la: o banco recusa excluir quem já comprou.
    // Devolve false quando o usuário não existe.
    bool Desativar(int id);
}
