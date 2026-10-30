using Microsoft.AspNetCore.Mvc;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Negocio;

namespace MundialTickets.Api.Controllers;

// Endpoints REST consumidos pelo aplicativo Flutter.
// O controller só recebe a requisição, chama o Negocio e escolhe o código HTTP.
[ApiController]
[Route("api/[controller]")]
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
        try
        {
            var estadio = _negocio.Cadastrar(dto.ParaEstadio());
            return CreatedAtAction(nameof(Obter), new { id = estadio.EstadioID }, EstadioDto.De(estadio));
        }
        catch (RegraDeNegocioException ex)
        {
            return BadRequest(new { erro = ex.Message });
        }
    }

    // PUT api/estadios/5   → 204 No Content
    [HttpPut("{id:int}")]
    public IActionResult Atualizar(int id, EstadioSalvarDto dto)
    {
        if (_negocio.ObterPorId(id) is null) return NotFound();

        try
        {
            _negocio.Atualizar(dto.ParaEstadio(id));
            return NoContent();
        }
        catch (RegraDeNegocioException ex)
        {
            return BadRequest(new { erro = ex.Message });
        }
    }

    // DELETE api/estadios/5   → 204 No Content (400 se tiver setores ou jogos)
    [HttpDelete("{id:int}")]
    public IActionResult Remover(int id)
    {
        try
        {
            return _negocio.Remover(id) ? NoContent() : NotFound();
        }
        catch (RegraDeNegocioException ex)
        {
            return BadRequest(new { erro = ex.Message });
        }
    }
}
