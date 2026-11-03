using Microsoft.AspNetCore.Mvc;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Negocio;
using MundialTickets.Web.ViewModels;

namespace MundialTickets.Web.Areas.Admin.Controllers;

// Administração dos assentos. Escolhe-se um setor, vê-se os assentos dele e há dois formulários:
// um assento por vez, e "criar vários" (a quantidade; o sistema numera A01, A02...).
public class AssentosController : AdminControllerBase
{
    private readonly AssentoNegocio _assentos;
    private readonly SetorNegocio _setores;
    private readonly EstadioNegocio _estadios;

    // INJEÇÃO DE DEPENDÊNCIA: o ASP.NET Core entrega os negócios prontos.
    public AssentosController(AssentoNegocio assentos, SetorNegocio setores, EstadioNegocio estadios)
    {
        _assentos = assentos;
        _setores = setores;
        _estadios = estadios;
    }

    // GET /Admin/Assentos                    escolha de setor
    // GET /Admin/Assentos?setorId=3          assentos do setor 3
    // GET /Admin/Assentos?setorId=3&editar=9 e o formulário preenchido com o assento 9
    [HttpGet]
    public IActionResult Index(int? setorId, int? editar)
    {
        if (editar.HasValue)
        {
            var assento = _assentos.ObterPorId(editar.Value);
            if (assento is null)
            {
                TempData["Erro"] = "Assento não encontrado.";
                return RedirectToAction(nameof(Index), new { setorId });
            }
            setorId = assento.SetorID;
        }
        return View(Montar(setorId, editar));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Salvar(int? id, AssentoSalvarDto formulario)
    {
        if (!ModelState.IsValid) return View(nameof(Index), Montar(formulario.SetorID, id, formulario));

        try
        {
            if (id.HasValue)
            {
                if (_assentos.ObterPorId(id.Value) is null) return NotFound();
                _assentos.Atualizar(formulario.ParaAssento(id.Value));
                TempData["Mensagem"] = "Assento atualizado.";
            }
            else
            {
                _assentos.Cadastrar(formulario.ParaAssento());
                TempData["Mensagem"] = "Assento cadastrado.";
            }
            return RedirectToAction(nameof(Index), new { setorId = formulario.SetorID });
        }
        catch (RegraDeNegocioException ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return View(nameof(Index), Montar(formulario.SetorID, id, formulario));
        }
    }

    // POST /Admin/Assentos/CriarEmLote   cria prefixo+01 até prefixo+quantidade, pulando os que já existem
    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult CriarEmLote(AssentoLoteDto lote)
    {
        if (!ModelState.IsValid) return View(nameof(Index), Montar(lote.SetorID, null, null, lote));

        try
        {
            var criados = _assentos.CriarEmLote(lote.SetorID, lote.Quantidade, lote.Prefixo);
            TempData["Mensagem"] = criados.Count == 1
                ? $"1 assento criado: {criados[0].Numero}."
                : $"{criados.Count} assentos criados, de {criados.First().Numero} a {criados.Last().Numero}.";
            return RedirectToAction(nameof(Index), new { setorId = lote.SetorID });
        }
        catch (RegraDeNegocioException ex)
        {
            ModelState.AddModelError("Lote", ex.Message);
            return View(nameof(Index), Montar(lote.SetorID, null, null, lote));
        }
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Excluir(int id, int setorId)
    {
        try
        {
            if (_assentos.Remover(id)) TempData["Mensagem"] = "Assento excluído.";
            else TempData["Erro"] = "Assento não encontrado.";
        }
        catch (RegraDeNegocioException ex)
        {
            TempData["Erro"] = ex.Message;   // por exemplo, o assento já tem ingresso
        }
        return RedirectToAction(nameof(Index), new { setorId });
    }

    private AssentosPaginaViewModel Montar(int? setorId, int? editar, AssentoSalvarDto? formulario = null, AssentoLoteDto? lote = null)
    {
        var modelo = new AssentosPaginaViewModel
        {
            Setores = _setores.Listar().Select(SetorDto.De).ToList(),
            Estadios = _estadios.Listar().Select(EstadioDto.De).ToList(),
            SetorId = setorId is > 0 ? setorId : null,
            IdEmEdicao = editar
        };

        if (modelo.SetorEscolhido is not null)
            modelo.Itens = _assentos.ListarPorSetor(modelo.SetorEscolhido.Id).Select(AssentoDto.De).ToList();

        if (formulario is not null) modelo.Formulario = formulario;
        else if (editar.HasValue && _assentos.ObterPorId(editar.Value) is { } assento) modelo.Formulario = AssentoSalvarDto.De(assento);
        else modelo.Formulario.SetorID = modelo.SetorId ?? 0;

        modelo.FormularioLote = lote ?? new AssentoLoteDto { SetorID = modelo.SetorId ?? 0, Quantidade = 10, Prefixo = "A" };
        return modelo;
    }
}
