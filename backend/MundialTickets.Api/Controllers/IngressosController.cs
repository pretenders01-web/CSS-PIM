using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MundialTickets.Modelos.Constantes;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Negocio;

namespace MundialTickets.Api.Controllers;

// Administração dos ingressos: só o perfil ADMIN entra. O comprador não usa estas rotas:
// ele vê os assentos disponíveis em /api/jogos/{id}/setores/{setorId}/assentos.
[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = PerfilUsuario.Admin)]
public class IngressosController : ControllerBase
{
    private readonly IngressoNegocio _negocio;

    // INJEÇÃO DE DEPENDÊNCIA: o ASP.NET Core entrega o negócio pronto.
    public IngressosController(IngressoNegocio negocio)
    {
        _negocio = negocio;
    }

    // GET api/ingressos                              → todos
    // GET api/ingressos?jogoId=1&status=DISPONIVEL   → filtrados (os dois filtros são opcionais)
    [HttpGet]
    public ActionResult<IEnumerable<IngressoDto>> Listar([FromQuery] int? jogoId, [FromQuery] string? status) =>
        Ok(_negocio.Listar(jogoId, status).Select(IngressoDto.De));

    // GET api/ingressos/100
    [HttpGet("{id:int}")]
    public ActionResult<IngressoDto> Obter(int id)
    {
        var ingresso = _negocio.ObterPorId(id);
        if (ingresso is null) return NotFound();
        return Ok(IngressoDto.De(ingresso));
    }

    // POST api/ingressos   → 201 Created + cabeçalho Location (um ingresso individual)
    [HttpPost]
    public ActionResult<IngressoDto> Cadastrar(IngressoSalvarDto dto)
    {
        var ingresso = _negocio.Cadastrar(dto.ParaIngresso());

        // Lê de novo para a resposta já trazer o nome do setor.
        return CreatedAtAction(nameof(Obter), new { id = ingresso.IngressoID }, IngressoDto.De(_negocio.ObterPorId(ingresso.IngressoID)!));
    }

    // POST api/ingressos/gerar   → 200 com { "criados": N }. Cria um ingresso por assento do
    // estádio do jogo; pode ser repetido sem duplicar (a segunda vez devolve zero).
    [HttpPost("gerar")]
    public IActionResult GerarParaJogo(IngressoGerarDto dto) =>
        Ok(new { criados = _negocio.GerarParaJogo(dto.JogoID) });

    // PUT api/ingressos/100/preco   → 204 No Content (só enquanto o ingresso está disponível)
    [HttpPut("{id:int}/preco")]
    public IActionResult AtualizarPreco(int id, IngressoPrecoDto dto)
    {
        if (_negocio.ObterPorId(id) is null) return NotFound();

        _negocio.AtualizarPreco(id, dto.PrecoFinal);
        return NoContent();
    }

    // POST api/ingressos/100/cancelar   → 200 com o ingresso cancelado
    [HttpPost("{id:int}/cancelar")]
    public ActionResult<IngressoDto> Cancelar(int id)
    {
        if (_negocio.ObterPorId(id) is null) return NotFound();
        return Ok(IngressoDto.De(_negocio.Cancelar(id)));
    }

    // DELETE api/ingressos/100   → 204 (400 se o ingresso já foi vendido)
    [HttpDelete("{id:int}")]
    public IActionResult Remover(int id) =>
        _negocio.Remover(id) ? NoContent() : NotFound();
}
