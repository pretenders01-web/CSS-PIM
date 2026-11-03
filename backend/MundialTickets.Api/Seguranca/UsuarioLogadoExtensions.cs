using System.Security.Claims;

namespace MundialTickets.Api.Seguranca;

public static class UsuarioLogadoExtensions
{
    // O id do usuário logado vem SEMPRE do token, nunca do corpo nem da URL da requisição:
    // assim ninguém consegue agir em nome de outro usuário.
    // Só deve ser chamado em ações protegidas por [Authorize].
    public static int ObterUsuarioId(this ClaimsPrincipal usuario) =>
        int.Parse(usuario.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? throw new InvalidOperationException("O token não tem o id do usuário."));
}
