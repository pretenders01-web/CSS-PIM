using Microsoft.AspNetCore.Mvc;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Negocio;
using MundialTickets.Web.Servicos;
using MundialTickets.Web.ViewModels;

namespace MundialTickets.Web.Controllers;

// Os jogos para o comprador: a lista (menu "Ingressos") e a página de um jogo, onde ele escolhe
// o setor e depois os assentos. É pública: só a compra exige login.
public class JogosController : Controller
{
    private readonly JogoNegocio _jogos;
    private readonly IngressoNegocio _ingressos;

    // INJEÇÃO DE DEPENDÊNCIA: o ASP.NET Core entrega os negócios prontos.
    public JogosController(JogoNegocio jogos, IngressoNegocio ingressos)
    {
        _jogos = jogos;
        _ingressos = ingressos;
    }

    // GET /Jogos
    public IActionResult Index()
    {
        var modelo = new JogosViewModel
        {
            Jogos = _jogos.Listar().Select(j => JogoCardViewModel.De(JogoDto.De(j))).ToList()
        };
        return View(modelo);
    }

    // GET /Jogos/Detalhes/1            → os setores do jogo
    // GET /Jogos/Detalhes/1?setorId=3  → os setores e, embaixo, os assentos disponíveis do setor 3
    public IActionResult Detalhes(int id, int? setorId)
    {
        var jogo = _jogos.ObterPorId(id);
        if (jogo is null) return NotFound();

        var modelo = new JogoDetalhesViewModel
        {
            Jogo = JogoCardViewModel.De(JogoDto.De(jogo)),
            Setores = _ingressos.ListarSetoresDoJogo(id),
            NoCarrinho = CarrinhoNaSessao.Obter(HttpContext.Session).ToHashSet()
        };

        if (setorId.HasValue)
        {
            try
            {
                modelo.Assentos = _ingressos.ListarAssentosDisponiveis(id, setorId.Value);
                modelo.SetorSelecionadoId = setorId;
            }
            catch (RegraDeNegocioException ex)
            {
                // Setor que não existe ou que não é deste jogo: volta para a lista de setores.
                TempData["Erro"] = ex.Message;
                return RedirectToAction(nameof(Detalhes), new { id });
            }
        }

        return View(modelo);
    }
}
