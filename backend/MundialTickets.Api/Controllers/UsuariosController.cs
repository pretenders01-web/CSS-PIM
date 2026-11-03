using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MundialTickets.Api.Seguranca;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Negocio;

namespace MundialTickets.Api.Controllers;

// Cadastro (público) e os dados do próprio usuário logado (/me).
// Não há rota para ver ou alterar OUTRO usuário: o id sempre vem do token.
[ApiController]
[Route("api/[controller]")]
public class UsuariosController : ControllerBase
{
    private readonly UsuarioNegocio _negocio;

    // INJEÇÃO DE DEPENDÊNCIA: o ASP.NET Core entrega o negócio pronto.
    public UsuariosController(UsuarioNegocio negocio)
    {
        _negocio = negocio;
    }

    // POST api/usuarios   → 201 Created (a conta nasce sempre com o perfil CLIENTE)
    [HttpPost]
    [AllowAnonymous]
    public ActionResult<UsuarioDto> Cadastrar(UsuarioCadastroDto dto)
    {
        var usuario = _negocio.Cadastrar(dto.ParaUsuario(), dto.Senha, dto.ConfirmarSenha);
        return CreatedAtAction(nameof(ObterMeusDados), null, UsuarioDto.De(usuario));
    }

    // GET api/usuarios/me
    [HttpGet("me")]
    [Authorize]
    public ActionResult<UsuarioDto> ObterMeusDados()
    {
        var usuario = _negocio.ObterPorId(User.ObterUsuarioId());

        // Conta apagada ou desativada depois que o token foi emitido: o token deixa de servir.
        if (usuario is null || !usuario.Ativo) return Unauthorized();

        return Ok(UsuarioDto.De(usuario));
    }

    // PUT api/usuarios/me   → 200 com os dados novos
    [HttpPut("me")]
    [Authorize]
    public ActionResult<UsuarioDto> AtualizarMeusDados(UsuarioAtualizarDto dto)
    {
        var usuario = _negocio.Atualizar(User.ObterUsuarioId(), dto.Nome, dto.Email, dto.Cpf, dto.NovaSenha, dto.ConfirmarNovaSenha);
        return Ok(UsuarioDto.De(usuario));
    }

    // DELETE api/usuarios/me   → 204. "Excluir a conta" desativa o usuário.
    [HttpDelete("me")]
    [Authorize]
    public IActionResult DesativarMinhaConta()
    {
        _negocio.Desativar(User.ObterUsuarioId());
        return NoContent();
    }
}
