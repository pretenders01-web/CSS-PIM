using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MundialTickets.Api.Seguranca;
using MundialTickets.Modelos.Constantes;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Negocio;

namespace MundialTickets.Api.Controllers;

// A compra, "meus ingressos" e a validação na portaria. Tudo aqui exige login, e o comprador é
// sempre quem está no token.
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

    // POST api/vendas/validar   → 200 com partida, setor, assento e data, ou 400 com o motivo da recusa.
    // Além do login exigido pela classe, esta rota exige o perfil ADMIN (quem opera a portaria).
    [HttpPost("validar")]
    [Authorize(Roles = PerfilUsuario.Admin)]
    public ActionResult<IngressoValidadoDto> ValidarIngresso(IngressoValidarDto dto) =>
        Ok(_negocio.ValidarIngresso(dto.CodigoQR));
}
