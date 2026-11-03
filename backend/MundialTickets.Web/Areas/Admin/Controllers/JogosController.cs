using Microsoft.AspNetCore.Mvc;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Negocio;
using MundialTickets.Web.ViewModels;

namespace MundialTickets.Web.Areas.Admin.Controllers;

// Administração dos jogos, em uma página só (tabela, formulário e exclusão).
// Atenção: esta é a página de ADMINISTRAÇÃO (/Admin/Jogos); a página do comprador é /Jogos.
public class JogosController : AdminControllerBase
{
    private readonly JogoNegocio _jogos;
    private readonly EstadioNegocio _estadios;

    // INJEÇÃO DE DEPENDÊNCIA: o ASP.NET Core entrega os negócios prontos.
    public JogosController(JogoNegocio jogos, EstadioNegocio estadios)
    {
        _jogos = jogos;
        _estadios = estadios;
    }

    [HttpGet]
    public IActionResult Index(int? editar)
    {
        if (editar.HasValue && _jogos.ObterPorId(editar.Value) is null)
        {
            TempData["Erro"] = "Jogo não encontrado.";
            return RedirectToAction(nameof(Index));
        }
        return View(Montar(editar));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Salvar(int? id, JogoSalvarDto formulario)
    {
        if (!ModelState.IsValid) return View(nameof(Index), Montar(id, formulario));

        try
        {
            if (id.HasValue)
            {
                if (_jogos.ObterPorId(id.Value) is null) return NotFound();
                _jogos.Atualizar(formulario.ParaJogo(id.Value));
                TempData["Mensagem"] = "Jogo atualizado.";
            }
            else
            {
                _jogos.Cadastrar(formulario.ParaJogo());
                TempData["Mensagem"] = "Jogo cadastrado. Para vender, gere os ingressos dele na página Ingressos.";
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
            if (_jogos.Remover(id)) TempData["Mensagem"] = "Jogo excluído.";
            else TempData["Erro"] = "Jogo não encontrado.";
        }
        catch (RegraDeNegocioException ex)
        {
            TempData["Erro"] = ex.Message;   // por exemplo, o jogo já tem ingressos
        }
        return RedirectToAction(nameof(Index));
    }

    private JogosPaginaViewModel Montar(int? editar, JogoSalvarDto? formulario = null)
    {
        var modelo = new JogosPaginaViewModel
        {
            Itens = _jogos.Listar().Select(JogoDto.De).ToList(),
            Estadios = _estadios.Listar().Select(EstadioDto.De).ToList(),
            IdEmEdicao = editar
        };

        if (formulario is not null) modelo.Formulario = formulario;
        else if (editar.HasValue && _jogos.ObterPorId(editar.Value) is { } jogo) modelo.Formulario = JogoSalvarDto.De(jogo);

        return modelo;
    }
}
