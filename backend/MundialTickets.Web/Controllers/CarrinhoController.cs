using Microsoft.AspNetCore.Mvc;
using MundialTickets.Modelos.Constantes;
using MundialTickets.Negocio;
using MundialTickets.Web.Servicos;

namespace MundialTickets.Web.Controllers;

// O carrinho de compras. Fica na sessão (só os ids dos ingressos) e não exige login: o login só é
// pedido na hora de pagar.
public class CarrinhoController : Controller
{
    private readonly IngressoNegocio _ingressos;

    // INJEÇÃO DE DEPENDÊNCIA: o ASP.NET Core entrega o negócio pronto.
    public CarrinhoController(IngressoNegocio ingressos)
    {
        _ingressos = ingressos;
    }

    // GET /Carrinho
    public IActionResult Index() =>
        View(CarrinhoMontador.Montar(_ingressos, HttpContext.Session));

    // POST /Carrinho/Adicionar   (vem do formulário da escolha de assentos)
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Adicionar(int jogoId, int setorId, List<int>? ingressoIds)
    {
        if (ingressoIds is null || ingressoIds.Count == 0)
        {
            TempData["Erro"] = "Marque ao menos um assento.";
            return RedirectToAction("Detalhes", "Jogos", new { id = jogoId, setorId });
        }

        // Só entra no carrinho o ingresso que existe, é deste jogo e ainda está disponível:
        // o formulário pode ter sido adulterado ou ter ficado aberto por muito tempo.
        var pedidos = ingressoIds.Distinct().ToList();
        var validos = _ingressos.ListarPorIds(pedidos)
            .Where(i => i.JogoID == jogoId && i.Status == StatusIngresso.Disponivel)
            .Select(i => i.IngressoID)
            .ToList();

        CarrinhoNaSessao.Adicionar(HttpContext.Session, validos);

        if (validos.Count > 0)
            TempData["Mensagem"] = validos.Count == 1 ? "1 assento adicionado ao carrinho." : $"{validos.Count} assentos adicionados ao carrinho.";
        if (validos.Count < pedidos.Count)
            TempData["Erro"] = "Algum assento marcado não estava mais disponível e não foi adicionado.";

        return RedirectToAction(nameof(Index));
    }

    // POST /Carrinho/Remover
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Remover(int ingressoId)
    {
        CarrinhoNaSessao.Remover(HttpContext.Session, ingressoId);
        return RedirectToAction(nameof(Index));
    }

    // POST /Carrinho/Limpar
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Limpar()
    {
        CarrinhoNaSessao.Limpar(HttpContext.Session);
        TempData["Mensagem"] = "Carrinho esvaziado.";
        return RedirectToAction(nameof(Index));
    }
}
