using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MundialTickets.Modelos.Constantes;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Negocio;

namespace MundialTickets.Api.Controllers;

// Administração dos assentos: só o perfil ADMIN entra.
[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = PerfilUsuario.Admin)]
public class AssentosController : ControllerBase
{
    private readonly AssentoNegocio _negocio;

    // INJEÇÃO DE DEPENDÊNCIA: o ASP.NET Core entrega o negócio pronto.
    public AssentosController(AssentoNegocio negocio)
    {
        _negocio = negocio;
    }

    // GET api/assentos?setorId=3   → os assentos de um setor (o setor é obrigatório)
    [HttpGet]
    public ActionResult<IEnumerable<AssentoDto>> ListarPorSetor([FromQuery] int setorId)
    {
        if (setorId <= 0) return BadRequest(new { erro = "Informe o setor (setorId)." });
        return Ok(_negocio.ListarPorSetor(setorId).Select(AssentoDto.De));
    }

    // GET api/assentos/10
    [HttpGet("{id:int}")]
    public ActionResult<AssentoDto> Obter(int id)
    {
        var assento = _negocio.ObterPorId(id);
        if (assento is null) return NotFound();
        return Ok(AssentoDto.De(assento));
    }

    // POST api/assentos   → 201 Created + cabeçalho Location
    [HttpPost]
    public ActionResult<AssentoDto> Cadastrar(AssentoSalvarDto dto)
    {
        var assento = _negocio.Cadastrar(dto.ParaAssento());
        return CreatedAtAction(nameof(Obter), new { id = assento.AssentoID }, AssentoDto.De(assento));
    }

    // POST api/assentos/lote   → 201 Created, com os assentos criados (A01, A02...)
    [HttpPost("lote")]
    public ActionResult<IEnumerable<AssentoDto>> CriarEmLote(AssentoLoteDto dto)
    {
        var criados = _negocio.CriarEmLote(dto.SetorID, dto.Quantidade, dto.Prefixo);
        return StatusCode(StatusCodes.Status201Created, criados.Select(AssentoDto.De));
    }

    // PUT api/assentos/10   → 204 No Content
    [HttpPut("{id:int}")]
    public IActionResult Atualizar(int id, AssentoSalvarDto dto)
    {
        if (_negocio.ObterPorId(id) is null) return NotFound();

        _negocio.Atualizar(dto.ParaAssento(id));
        return NoContent();
    }

    // DELETE api/assentos/10   → 204 (400 se o assento já tiver ingresso)
    [HttpDelete("{id:int}")]
    public IActionResult Remover(int id) =>
        _negocio.Remover(id) ? NoContent() : NotFound();
}
