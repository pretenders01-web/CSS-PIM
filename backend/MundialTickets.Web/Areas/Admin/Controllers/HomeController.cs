using Microsoft.AspNetCore.Mvc;

namespace MundialTickets.Web.Areas.Admin.Controllers;

// Início da administração: os atalhos para as páginas de cadastro.
public class HomeController : AdminControllerBase
{
    public IActionResult Index() => View();
}
