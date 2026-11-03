using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MundialTickets.Api.Seguranca;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Negocio;

namespace MundialTickets.Api.Controllers;

// A compra e "meus ingressos". Tudo aqui exige login, e o comprador é sempre quem está no token.
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class VendasController : ControllerBase
{
    private readonly VendaNegocio _negocio;

    // INJEÇÃO DE DEPENDÊNCIA: o ASP.NET Core entrega o negócio pronto.
    public VendasController(VendaNegocio negocio)
    {
        _negocio = negocio;
    }

    // POST api/vendas   → 201 Created, com uma linha por ingresso comprado (código do QR, jogo e partida).
    // É aqui que, depois das conferências do Negócio, a stored procedure sp_RealizarCompra é executada.
    // O corpo NÃO tem o usuário: ele vem do token.
    [HttpPost]
    public ActionResult<List<CompraResultadoDto>> Comprar(CompraPedidoDto dto)
    {
        var comprados = _negocio.Comprar(User.ObterUsuarioId(), dto.IngressoIds, dto.MetodoPagamento);
        return StatusCode(StatusCodes.Status201Created, comprados);
    }

    // GET api/vendas/meus-ingressos
    [HttpGet("meus-ingressos")]
    public ActionResult<List<IngressoCompradoDto>> ListarMeusIngressos() =>
        Ok(_negocio.ListarIngressosDoUsuario(User.ObterUsuarioId()));
}
