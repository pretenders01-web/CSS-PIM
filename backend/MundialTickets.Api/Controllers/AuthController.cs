using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MundialTickets.Api.Seguranca;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Negocio;

namespace MundialTickets.Api.Controllers;

// Login do app: confere e-mail e senha e devolve o token JWT.
[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly UsuarioNegocio _usuarios;
    private readonly IGeradorDeToken _tokens;

    // INJEÇÃO DE DEPENDÊNCIA: o ASP.NET Core entrega o negócio e o gerador de token prontos.
    public AuthController(UsuarioNegocio usuarios, IGeradorDeToken tokens)
    {
        _usuarios = usuarios;
        _tokens = tokens;
    }

    // POST api/auth/login   → 200 com o token, ou 401 se e-mail/senha estiverem errados
    [HttpPost("login")]
    [AllowAnonymous]
    public ActionResult<LoginRespostaDto> Login(LoginDto dto)
    {
        try
        {
            var usuario = _usuarios.Autenticar(dto.Email, dto.Senha);
            var (token, expiraEm) = _tokens.Gerar(usuario);

            return Ok(new LoginRespostaDto
            {
                Token = token,
                ExpiraEm = expiraEm,
                Usuario = UsuarioDto.De(usuario)
            });
        }
        catch (RegraDeNegocioException ex)
        {
            // Login recusado é 401 (não autenticado), e não o 400 que o filtro geral devolveria.
            return Unauthorized(new { erro = ex.Message });
        }
    }
}
