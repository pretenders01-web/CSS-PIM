using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MundialTickets.Negocio;
using MundialTickets.Web.Servicos;
using MundialTickets.Web.ViewModels;

namespace MundialTickets.Web.Controllers;

// O pagamento (simulado). Exige login: quem não está logado é levado ao login e volta para cá.
// É aqui que o comprador confirma e o VendaNegocio faz a compra, executando a stored procedure.
[Authorize]
public class PagamentoController : Controller
{
    private readonly IngressoNegocio _ingressos;
    private readonly VendaNegocio _vendas;

    // INJEÇÃO DE DEPENDÊNCIA: o ASP.NET Core entrega os negócios prontos.
    public PagamentoController(IngressoNegocio ingressos, VendaNegocio vendas)
    {
        _ingressos = ingressos;
        _vendas = vendas;
    }

    // GET /Pagamento
    public IActionResult Index()
    {
        var carrinho = CarrinhoMontador.Montar(_ingressos, HttpContext.Session);

        var desvio = ValidarCarrinho(carrinho);
        if (desvio is not null) return desvio;

        return View(new PagamentoViewModel { Carrinho = carrinho });
    }

    // POST /Pagamento/Confirmar
    // O Bind aceita só o campo da forma de pagamento: o resto da tela não vem do formulário.
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Confirmar([Bind("MetodoPagamento")] PagamentoViewModel modelo)
    {
        var carrinho = CarrinhoMontador.Montar(_ingressos, HttpContext.Session);
        modelo.Carrinho = carrinho;

        var desvio = ValidarCarrinho(carrinho);
        if (desvio is not null) return desvio;

        if (!ModelState.IsValid) return View(nameof(Index), modelo);

        try
        {
            // O comprador é quem está logado (cookie); o preço vem do banco, nunca do formulário.
            var comprados = _vendas.Comprar(User.ObterUsuarioId(), carrinho.Itens.Select(i => i.IngressoId), modelo.MetodoPagamento);

            CarrinhoNaSessao.Limpar(HttpContext.Session);
            TempData["Mensagem"] = comprados.Count == 1
                ? "Compra aprovada! Seu ingresso e o código do QR estão abaixo."
                : $"Compra aprovada! Seus {comprados.Count} ingressos e os códigos do QR estão abaixo.";
            return RedirectToAction("Index", "MeusIngressos");
        }
        catch (RegraDeNegocioException ex)
        {
            // Pagamento não aprovado (boleto), assento vendido no meio do caminho etc.
            ModelState.AddModelError(string.Empty, ex.Message);
            return View(nameof(Index), modelo);
        }
    }

    // Carrinho vazio ou com assento que deixou de estar disponível: volta ao carrinho para ajustar.
    private IActionResult? ValidarCarrinho(CarrinhoViewModel carrinho)
    {
        if (carrinho.Itens.Count == 0)
        {
            TempData["Erro"] = "Seu carrinho está vazio.";
            return RedirectToAction("Index", "Carrinho");
        }

        if (carrinho.TemIndisponivel)
        {
            TempData["Erro"] = "Alguns assentos do carrinho não estão mais disponíveis. Remova-os para continuar.";
            return RedirectToAction("Index", "Carrinho");
        }

        return null;
    }
}
