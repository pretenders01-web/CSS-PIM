using Microsoft.AspNetCore.Mvc;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Negocio;
using MundialTickets.Web.ViewModels;

namespace MundialTickets.Web.Areas.Admin.Controllers;

// Administração dos setores, em uma página só (tabela, formulário e exclusão), como a de Estádios.
// O estádio do setor é escolhido em uma lista.
public class SetoresController : AdminControllerBase
{
    private readonly SetorNegocio _setores;
    private readonly EstadioNegocio _estadios;

    // INJEÇÃO DE DEPENDÊNCIA: o ASP.NET Core entrega os negócios prontos.
    public SetoresController(SetorNegocio setores, EstadioNegocio estadios)
    {
        _setores = setores;
        _estadios = estadios;
    }

    [HttpGet]
    public IActionResult Index(int? editar)
    {
        if (editar.HasValue && _setores.ObterPorId(editar.Value) is null)
        {
            TempData["Erro"] = "Setor não encontrado.";
            return RedirectToAction(nameof(Index));
        }
        return View(Montar(editar));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Salvar(int? id, SetorSalvarDto formulario)
    {
        if (!ModelState.IsValid) return View(nameof(Index), Montar(id, formulario));

        try
        {
            if (id.HasValue)
            {
                if (_setores.ObterPorId(id.Value) is null) return NotFound();
                _setores.Atualizar(formulario.ParaSetor(id.Value));
                TempData["Mensagem"] = "Setor atualizado.";
            }
            else
            {
                _setores.Cadastrar(formulario.ParaSetor());
                TempData["Mensagem"] = "Setor cadastrado.";
            }
            return RedirectToAction(nameof(Index));
        }
        catch (RegraDeNegocioException ex)
        {
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
            if (_setores.Remover(id)) TempData["Mensagem"] = "Setor excluído.";
            else TempData["Erro"] = "Setor não encontrado.";
        }
        catch (RegraDeNegocioException ex)
        {
            TempData["Erro"] = ex.Message;   // por exemplo, o setor ainda tem assentos ou ingressos
        }
        return RedirectToAction(nameof(Index));
    }

    private SetoresPaginaViewModel Montar(int? editar, SetorSalvarDto? formulario = null)
    {
        var modelo = new SetoresPaginaViewModel
        {
            Itens = _setores.Listar().Select(SetorDto.De).ToList(),
            Estadios = _estadios.Listar().Select(EstadioDto.De).ToList(),
            IdEmEdicao = editar
        };

        if (formulario is not null) modelo.Formulario = formulario;
        else if (editar.HasValue && _setores.ObterPorId(editar.Value) is { } setor) modelo.Formulario = SetorSalvarDto.De(setor);

        return modelo;
    }
}
