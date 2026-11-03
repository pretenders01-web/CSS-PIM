using System.Security.Claims;

namespace MundialTickets.Web.Servicos;

public static class UsuarioLogadoExtensions
{
    // O id do usuário logado vem SEMPRE do cookie de login, nunca de um campo do formulário
    // nem da URL: assim ninguém consegue agir em nome de outro usuário.
    // Só deve ser chamado em ações protegidas por [Authorize].
    public static int ObterUsuarioId(this ClaimsPrincipal usuario) =>
        int.Parse(usuario.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? throw new InvalidOperationException("O login não tem o id do usuário."));
}
