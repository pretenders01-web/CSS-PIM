using Microsoft.AspNetCore.Mvc;
using MundialTickets.Modelos;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Negocio;
using MundialTickets.Web.ViewModels;

namespace MundialTickets.Web.Areas.Admin.Controllers;

// Administração dos ingressos. Não é um cadastro um a um: o normal é GERAR os ingressos de um jogo
// (um por assento do estádio dele). Também dá para criar um ingresso individual, ajustar o preço
// de um disponível, cancelar e excluir. Os filtros (jogo e situação) são mantidos depois de cada ação.
public class IngressosController : AdminControllerBase
{
    private readonly IngressoNegocio _ingressos;
    private readonly JogoNegocio _jogos;
    private readonly SetorNegocio _setores;
    private readonly AssentoNegocio _assentos;

    // INJEÇÃO DE DEPENDÊNCIA: o ASP.NET Core entrega os negócios prontos.
    public IngressosController(IngressoNegocio ingressos, JogoNegocio jogos, SetorNegocio setores, AssentoNegocio assentos)
    {
        _ingressos = ingressos;
        _jogos = jogos;
        _setores = setores;
        _assentos = assentos;
    }

    // GET /Admin/Ingressos?jogoId=3&status=DISPONIVEL
    [HttpGet]
    public IActionResult Index(int? jogoId, string? status)
    {
        var modelo = new IngressosPaginaViewModel
        {
            Jogos = _jogos.Listar().Select(JogoDto.De).ToList(),
            JogoId = jogoId is > 0 ? jogoId : null,
            Status = string.IsNullOrWhiteSpace(status) ? null : status
        };

        try
        {
            modelo.Itens = _ingressos.Listar(modelo.JogoId, modelo.Status)
                .Select(i => new IngressoLinhaViewModel
                {
                    Id = i.IngressoID,
                    Partida = i.Jogo is null ? "?" : $"{i.Jogo.TimeA} x {i.Jogo.TimeB}",
                    NomeSetor = i.Setor?.NomeSetor ?? "?",
                    NumeroAssento = i.NumeroAssento ?? i.Assento?.Numero ?? "—",
                    PrecoFinal = i.PrecoFinal,
                    Status = i.Status
                })
                .ToList();
        }
        catch (RegraDeNegocioException ex)
        {
            TempData["Erro"] = ex.Message;   // situação inválida na URL
            return RedirectToAction(nameof(Index), new { jogoId = modelo.JogoId });
        }

        if (modelo.JogoId.HasValue)
        {
            modelo.AssentosLivres = AssentosSemIngresso(modelo.JogoId.Value);
            modelo.Novo.JogoID = modelo.JogoId.Value;
        }
        modelo.Gerar.JogoID = modelo.JogoId ?? 0;

        return View(modelo);
    }

    // POST /Admin/Ingressos/Gerar   cria os ingressos de um jogo; pode ser repetido sem duplicar
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Gerar(IngressoGerarDto dto)
    {
        if (!ModelState.IsValid)
        {
            TempData["Erro"] = "Escolha o jogo.";
            return RedirectToAction(nameof(Index));
        }

        try
        {
            var criados = _ingressos.GerarParaJogo(dto.JogoID);
            TempData["Mensagem"] = criados == 0
                ? "Este jogo já tem ingresso para todos os assentos do estádio. Nada foi criado."
                : criados == 1 ? "1 ingresso gerado." : $"{criados} ingressos gerados.";
        }
        catch (RegraDeNegocioException ex)
        {
            TempData["Erro"] = ex.Message;
        }
        return RedirectToAction(nameof(Index), new { jogoId = dto.JogoID });
    }

    // POST /Admin/Ingressos/Novo   um ingresso individual; o setor vem do assento escolhido
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Novo(NovoIngressoViewModel novo)
    {
        try
        {
            var assento = _assentos.ObterPorId(novo.AssentoID)
                ?? throw new RegraDeNegocioException("Escolha o assento.");

            _ingressos.Cadastrar(new Ingresso
            {
                JogoID = novo.JogoID,
                SetorID = assento.SetorID,
                AssentoID = assento.AssentoID,
                PrecoFinal = novo.PrecoFinal
            });
            TempData["Mensagem"] = "Ingresso criado.";
        }
        catch (RegraDeNegocioException ex)
        {
            TempData["Erro"] = ex.Message;
        }
        return RedirectToAction(nameof(Index), new { jogoId = novo.JogoID });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult AtualizarPreco(int id, decimal precoFinal, int? jogoId, string? status)
    {
        try
        {
            _ingressos.AtualizarPreco(id, precoFinal);
            TempData["Mensagem"] = "Preço atualizado.";
        }
        catch (RegraDeNegocioException ex)
        {
            TempData["Erro"] = ex.Message;
        }
        return RedirectToAction(nameof(Index), new { jogoId, status });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Cancelar(int id, int? jogoId, string? status)
    {
        try
        {
            _ingressos.Cancelar(id);
            TempData["Mensagem"] = "Ingresso cancelado.";
        }
        catch (RegraDeNegocioException ex)
        {
            TempData["Erro"] = ex.Message;   // por exemplo, um ingresso vendido não pode ser cancelado
        }
        return RedirectToAction(nameof(Index), new { jogoId, status });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Excluir(int id, int? jogoId, string? status)
    {
        try
        {
            if (_ingressos.Remover(id)) TempData["Mensagem"] = "Ingresso excluído.";
            else TempData["Erro"] = "Ingresso não encontrado.";
        }
        catch (RegraDeNegocioException ex)
        {
            TempData["Erro"] = ex.Message;   // por exemplo, o ingresso já foi vendido
        }
        return RedirectToAction(nameof(Index), new { jogoId, status });
    }

    // Os assentos do estádio do jogo que ainda não têm ingresso neste jogo (lista do formulário individual).
    private List<AssentoLivreViewModel> AssentosSemIngresso(int jogoId)
    {
        var jogo = _jogos.ObterPorId(jogoId);
        if (jogo is null) return new List<AssentoLivreViewModel>();

        var jaTem = _ingressos.Listar(jogoId)
            .Where(i => i.AssentoID.HasValue)
            .Select(i => i.AssentoID!.Value)
            .ToHashSet();

        var livres = new List<AssentoLivreViewModel>();
        foreach (var setor in _setores.ListarPorEstadio(jogo.EstadioID))
            foreach (var assento in _assentos.ListarPorSetor(setor.SetorID).Where(a => !jaTem.Contains(a.AssentoID)))
                livres.Add(new AssentoLivreViewModel
                {
                    AssentoId = assento.AssentoID,
                    Rotulo = $"{setor.NomeSetor} — {assento.Numero}",
                    PrecoBase = setor.PrecoBase
                });
        return livres;
    }
}
