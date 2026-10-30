using Microsoft.AspNetCore.Mvc;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Negocio;

namespace MundialTickets.Api.Controllers;

// Endpoints REST consumidos pelo aplicativo Flutter.
// O controller só recebe a requisição, chama o Negocio e escolhe o código HTTP.
[ApiController]
[Route("api/[controller]")]
public class ClientesController : ControllerBase
{
    private readonly ClienteNegocio _negocio;

    // INJEÇÃO DE DEPENDÊNCIA: o controller não escreve "new ClienteNegocio(...)".
    // Ele pede um ClienteNegocio no construtor e o ASP.NET Core entrega pronto,
    // já com o repositório e o banco montados por dentro. A lista do que o ASP.NET
    // sabe montar está no Program.cs. Explicação completa: INJECAO-DE-DEPENDENCIA.md.
    public ClientesController(ClienteNegocio negocio)
    {
        _negocio = negocio;
    }

    // GET api/clientes
    [HttpGet]
    public ActionResult<IEnumerable<ClienteDto>> Listar()
    {
        var clientes = _negocio.Listar();
        return Ok(clientes.Select(ClienteDto.De));
    }

    // GET api/clientes/5
    [HttpGet("{id:int}")]
    public ActionResult<ClienteDto> Obter(int id)
    {
        var cliente = _negocio.ObterPorId(id);
        if (cliente is null) return NotFound();
        return Ok(ClienteDto.De(cliente));
    }

    // GET api/clientes/buscar?nome=ana   (executa a stored procedure)
    [HttpGet("buscar")]
    public ActionResult<IEnumerable<ClienteDto>> Buscar([FromQuery] string nome)
    {
        var clientes = _negocio.BuscarPorNome(nome);
        return Ok(clientes.Select(ClienteDto.De));
    }

    // POST api/clientes   → 201 Created + cabeçalho Location
    [HttpPost]
    public ActionResult<ClienteDto> Cadastrar(ClienteSalvarDto dto)
    {
        try
        {
            var cliente = _negocio.Cadastrar(dto.ParaCliente());
            return CreatedAtAction(nameof(Obter), new { id = cliente.Id }, ClienteDto.De(cliente));
        }
        catch (RegraDeNegocioException ex)
        {
            return BadRequest(new { erro = ex.Message });
        }
    }

    // PUT api/clientes/5   → 204 No Content
    [HttpPut("{id:int}")]
    public IActionResult Atualizar(int id, ClienteSalvarDto dto)
    {
        if (_negocio.ObterPorId(id) is null) return NotFound();

        try
        {
            _negocio.Atualizar(dto.ParaCliente(id));
            return NoContent();
        }
        catch (RegraDeNegocioException ex)
        {
            return BadRequest(new { erro = ex.Message });
        }
    }

    // DELETE api/clientes/5   → 204 No Content
    [HttpDelete("{id:int}")]
    public IActionResult Remover(int id)
    {
        var removido = _negocio.Remover(id);
        return removido ? NoContent() : NotFound();
    }
}
