using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MundialTickets.Modelos.Constantes;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Negocio;

namespace MundialTickets.Api.Controllers;

// Administração dos estádios: só o perfil ADMIN entra. O controller só recebe a requisição,
// chama o Negocio e escolhe o código HTTP; as regras que falham viram "400" no filtro geral.
[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = PerfilUsuario.Admin)]
public class EstadiosController : ControllerBase
{
    private readonly EstadioNegocio _negocio;

    // INJEÇÃO DE DEPENDÊNCIA: o controller não escreve "new EstadioNegocio(...)".
    // Ele pede um EstadioNegocio no construtor e o ASP.NET Core entrega pronto.
    // Explicação completa: INJECAO-DE-DEPENDENCIA.md.
    public EstadiosController(EstadioNegocio negocio)
    {
        _negocio = negocio;
    }

    // GET api/estadios
    [HttpGet]
    public ActionResult<IEnumerable<EstadioDto>> Listar() =>
        Ok(_negocio.Listar().Select(EstadioDto.De));

    // GET api/estadios/5
    [HttpGet("{id:int}")]
    public ActionResult<EstadioDto> Obter(int id)
    {
        var estadio = _negocio.ObterPorId(id);
        if (estadio is null) return NotFound();
        return Ok(EstadioDto.De(estadio));
    }

    // POST api/estadios   → 201 Created + cabeçalho Location
    [HttpPost]
    public ActionResult<EstadioDto> Cadastrar(EstadioSalvarDto dto)
    {
        var estadio = _negocio.Cadastrar(dto.ParaEstadio());
        return CreatedAtAction(nameof(Obter), new { id = estadio.EstadioID }, EstadioDto.De(estadio));
    }

    // PUT api/estadios/5   → 204 No Content
    [HttpPut("{id:int}")]
    public IActionResult Atualizar(int id, EstadioSalvarDto dto)
    {
        if (_negocio.ObterPorId(id) is null) return NotFound();

        _negocio.Atualizar(dto.ParaEstadio(id));
        return NoContent();
    }

    // DELETE api/estadios/5   → 204 No Content (400 se tiver setores ou jogos)
    [HttpDelete("{id:int}")]
    public IActionResult Remover(int id) =>
        _negocio.Remover(id) ? NoContent() : NotFound();
}
