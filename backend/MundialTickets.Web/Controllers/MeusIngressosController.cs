using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MundialTickets.Negocio;
using MundialTickets.Web.Servicos;
using MundialTickets.Web.ViewModels;

namespace MundialTickets.Web.Controllers;

// Os ingressos que o usuário logado já comprou, com o código do QR.
[Authorize]
public class MeusIngressosController : Controller
{
    private readonly VendaNegocio _vendas;

    // INJEÇÃO DE DEPENDÊNCIA: o ASP.NET Core entrega o negócio pronto.
    public MeusIngressosController(VendaNegocio vendas)
    {
        _vendas = vendas;
    }

    // GET /MeusIngressos
    public IActionResult Index() =>
        View(new MeusIngressosViewModel { Ingressos = _vendas.ListarIngressosDoUsuario(User.ObterUsuarioId()) });
}
