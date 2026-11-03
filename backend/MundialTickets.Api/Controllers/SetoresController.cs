using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MundialTickets.Modelos.Constantes;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Negocio;

namespace MundialTickets.Api.Controllers;

// Administração dos setores dos estádios: só o perfil ADMIN entra.
[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = PerfilUsuario.Admin)]
public class SetoresController : ControllerBase
{
    private readonly SetorNegocio _negocio;

    // INJEÇÃO DE DEPENDÊNCIA: o ASP.NET Core entrega o negócio pronto.
    public SetoresController(SetorNegocio negocio)
    {
        _negocio = negocio;
    }

    // GET api/setores              → todos
    // GET api/setores?estadioId=1  → só os de um estádio
    [HttpGet]
    public ActionResult<IEnumerable<SetorDto>> Listar([FromQuery] int? estadioId)
    {
        var setores = estadioId.HasValue ? _negocio.ListarPorEstadio(estadioId.Value) : _negocio.Listar();
        return Ok(setores.Select(SetorDto.De));
    }

    // GET api/setores/3
    [HttpGet("{id:int}")]
    public ActionResult<SetorDto> Obter(int id)
    {
        var setor = _negocio.ObterPorId(id);
        if (setor is null) return NotFound();
        return Ok(SetorDto.De(setor));
    }

    // POST api/setores   → 201 Created + cabeçalho Location
    [HttpPost]
    public ActionResult<SetorDto> Cadastrar(SetorSalvarDto dto)
    {
        var setor = _negocio.Cadastrar(dto.ParaSetor());
        return CreatedAtAction(nameof(Obter), new { id = setor.SetorID }, SetorDto.De(setor));
    }

    // PUT api/setores/3   → 204 No Content
    [HttpPut("{id:int}")]
    public IActionResult Atualizar(int id, SetorSalvarDto dto)
    {
        if (_negocio.ObterPorId(id) is null) return NotFound();

        _negocio.Atualizar(dto.ParaSetor(id));
        return NoContent();
    }

    // DELETE api/setores/3   → 204 (400 se o setor tiver assentos ou ingressos)
    [HttpDelete("{id:int}")]
    public IActionResult Remover(int id) =>
        _negocio.Remover(id) ? NoContent() : NotFound();
}
