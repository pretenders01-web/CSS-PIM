using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MundialTickets.Modelos.Constantes;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Negocio;

namespace MundialTickets.Api.Controllers;

// Os jogos. A consulta é pública (o comprador escolhe o jogo, o setor e o assento);
// cadastrar, alterar e excluir são só do administrador.
[ApiController]
[Route("api/[controller]")]
public class JogosController : ControllerBase
{
    private readonly JogoNegocio _jogos;
    private readonly IngressoNegocio _ingressos;

    // INJEÇÃO DE DEPENDÊNCIA: o ASP.NET Core entrega os negócios prontos.
    public JogosController(JogoNegocio jogos, IngressoNegocio ingressos)
    {
        _jogos = jogos;
        _ingressos = ingressos;
    }

    // ---------- público ----------

    // GET api/jogos
    [HttpGet]
    public ActionResult<IEnumerable<JogoDto>> Listar() =>
        Ok(_jogos.Listar().Select(JogoDto.De));

    // GET api/jogos/1
    [HttpGet("{id:int}")]
    public ActionResult<JogoDto> Obter(int id)
    {
        var jogo = _jogos.ObterPorId(id);
        if (jogo is null) return NotFound();
        return Ok(JogoDto.De(jogo));
    }

    // GET api/jogos/1/setores   → os setores do jogo, com o preço e quantos assentos restam
    [HttpGet("{id:int}/setores")]
    public ActionResult<IEnumerable<SetorDisponibilidadeDto>> ListarSetores(int id)
    {
        if (_jogos.ObterPorId(id) is null) return NotFound();
        return Ok(_ingressos.ListarSetoresDoJogo(id));
    }

    // GET api/jogos/1/setores/3/assentos   → os assentos disponíveis do setor, já com o id do ingresso
    [HttpGet("{id:int}/setores/{setorId:int}/assentos")]
    public ActionResult<IEnumerable<AssentoDisponivelDto>> ListarAssentosDisponiveis(int id, int setorId)
    {
        if (_jogos.ObterPorId(id) is null) return NotFound();
        return Ok(_ingressos.ListarAssentosDisponiveis(id, setorId));
    }

    // ---------- administração ----------

    // POST api/jogos   → 201 Created + cabeçalho Location
    [HttpPost]
    [Authorize(Roles = PerfilUsuario.Admin)]
    public ActionResult<JogoDto> Cadastrar(JogoSalvarDto dto)
    {
        var jogo = _jogos.Cadastrar(dto.ParaJogo());

        // Lê de novo para a resposta já trazer o nome do estádio.
        return CreatedAtAction(nameof(Obter), new { id = jogo.JogoID }, JogoDto.De(_jogos.ObterPorId(jogo.JogoID)!));
    }

    // PUT api/jogos/1   → 204 No Content
    [HttpPut("{id:int}")]
    [Authorize(Roles = PerfilUsuario.Admin)]
    public IActionResult Atualizar(int id, JogoSalvarDto dto)
    {
        if (_jogos.ObterPorId(id) is null) return NotFound();

        _jogos.Atualizar(dto.ParaJogo(id));
        return NoContent();
    }

    // DELETE api/jogos/1   → 204 (400 se o jogo já tem ingressos)
    [HttpDelete("{id:int}")]
    [Authorize(Roles = PerfilUsuario.Admin)]
    public IActionResult Remover(int id) =>
        _jogos.Remover(id) ? NoContent() : NotFound();
}
