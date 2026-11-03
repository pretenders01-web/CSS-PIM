using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Negocio;
using MundialTickets.Web.Models;
using MundialTickets.Web.ViewModels;

namespace MundialTickets.Web.Controllers;

// Página inicial: o banner e o carrossel com os jogos.
// Controller MVC: recebe a requisição, chama o Negócio e devolve uma view.
// Nenhuma regra de negócio aqui; elas estão nas classes de Negócio.
public class HomeController : Controller
{
    private readonly JogoNegocio _jogos;

    // INJEÇÃO DE DEPENDÊNCIA: o ASP.NET Core entrega o negócio pronto.
    public HomeController(JogoNegocio jogos)
    {
        _jogos = jogos;
    }

    public IActionResult Index()
    {
        var modelo = new JogosViewModel
        {
            Jogos = _jogos.Listar().Select(j => JogoCardViewModel.De(JogoDto.De(j))).ToList()
        };
        return View(modelo);
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
