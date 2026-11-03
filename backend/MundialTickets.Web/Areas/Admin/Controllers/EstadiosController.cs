using Microsoft.AspNetCore.Mvc;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Negocio;
using MundialTickets.Web.ViewModels;

namespace MundialTickets.Web.Areas.Admin.Controllers;

// Administração dos estádios, em UMA página: a tabela, o formulário e a exclusão juntos.
//   GET  /Admin/Estadios              tabela + formulário vazio (cadastrar)
//   GET  /Admin/Estadios?editar=5     tabela + formulário preenchido (alterar)
//   POST /Admin/Estadios/Salvar       cadastra (sem id) ou altera (com id)
//   POST /Admin/Estadios/Excluir      exclui, com confirmação
// O controller só recebe, chama o Negócio e devolve a view; as regras estão no EstadioNegocio.
public class EstadiosController : AdminControllerBase
{
    private readonly EstadioNegocio _negocio;

    // INJEÇÃO DE DEPENDÊNCIA: o ASP.NET Core entrega o negócio pronto.
    public EstadiosController(EstadioNegocio negocio)
    {
        _negocio = negocio;
    }

    [HttpGet]
    public IActionResult Index(int? editar)
    {
        if (editar.HasValue && _negocio.ObterPorId(editar.Value) is null)
        {
            TempData["Erro"] = "Estádio não encontrado.";
            return RedirectToAction(nameof(Index));
        }
        return View(Montar(editar));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Salvar(int? id, EstadioSalvarDto formulario)
    {
        if (!ModelState.IsValid) return View(nameof(Index), Montar(id, formulario));

        try
        {
            if (id.HasValue)
            {
                if (_negocio.ObterPorId(id.Value) is null) return NotFound();
                _negocio.Atualizar(formulario.ParaEstadio(id.Value));
                TempData["Mensagem"] = "Estádio atualizado.";
            }
            else
            {
                _negocio.Cadastrar(formulario.ParaEstadio());
                TempData["Mensagem"] = "Estádio cadastrado.";
            }
            return RedirectToAction(nameof(Index));
        }
        catch (RegraDeNegocioException ex)
        {
            // A regra violada aparece no topo do formulário, e o que foi digitado é mantido.
            ModelState.AddModelError(string.Empty, ex.Message);
            return View(nameof(Index), Montar(id, formulario));
        }
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Excluir(int id)
    {
        try
        {
            if (_negocio.Remover(id)) TempData["Mensagem"] = "Estádio excluído.";
            else TempData["Erro"] = "Estádio não encontrado.";
        }
        catch (RegraDeNegocioException ex)
        {
            TempData["Erro"] = ex.Message;   // por exemplo, o estádio ainda tem setores ou jogos
        }
        return RedirectToAction(nameof(Index));
    }

    private PaginaAdminViewModel<EstadioDto, EstadioSalvarDto> Montar(int? editar, EstadioSalvarDto? formulario = null)
    {
        var modelo = new PaginaAdminViewModel<EstadioDto, EstadioSalvarDto>
        {
            Itens = _negocio.Listar().Select(EstadioDto.De).ToList(),
            IdEmEdicao = editar
        };

        if (formulario is not null) modelo.Formulario = formulario;
        else if (editar.HasValue && _negocio.ObterPorId(editar.Value) is { } estadio) modelo.Formulario = EstadioSalvarDto.De(estadio);

        return modelo;
    }
}
