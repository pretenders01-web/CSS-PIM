using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MundialTickets.Modelos;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Negocio;
using MundialTickets.Web.Servicos;
using MundialTickets.Web.ViewModels;

namespace MundialTickets.Web.Controllers;

// Login, cadastro, sair e "Minha conta" (ver, alterar e desativar a própria conta).
// Todas as regras (senha, e-mail único, conta desativada) estão no UsuarioNegocio.
public class ContaController : Controller
{
    private readonly UsuarioNegocio _usuarios;

    // INJEÇÃO DE DEPENDÊNCIA: o ASP.NET Core entrega o negócio pronto.
    public ContaController(UsuarioNegocio usuarios)
    {
        _usuarios = usuarios;
    }

    // ---------- entrar ----------

    [HttpGet]
    public IActionResult Entrar(string? returnUrl = null)
    {
        if (User.Identity?.IsAuthenticated == true) return RedirectToAction("Index", "Home");
        return View(new LoginViewModel { ReturnUrl = returnUrl });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Entrar(LoginViewModel modelo)
    {
        if (!ModelState.IsValid) return View(modelo);

        try
        {
            var usuario = _usuarios.Autenticar(modelo.Email, modelo.Senha);
            await EntrarNoSistemaAsync(usuario);

            // Só volta para endereços DO PRÓPRIO SITE: um endereço de fora seria um redirecionamento aberto.
            return Url.IsLocalUrl(modelo.ReturnUrl) ? LocalRedirect(modelo.ReturnUrl!) : RedirectToAction("Index", "Home");
        }
        catch (RegraDeNegocioException ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return View(modelo);
        }
    }

    // ---------- cadastro ----------

    [HttpGet]
    public IActionResult Cadastro()
    {
        if (User.Identity?.IsAuthenticated == true) return RedirectToAction("Index", "Home");
        return View(new UsuarioCadastroDto());
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Cadastro(UsuarioCadastroDto modelo)
    {
        if (!ModelState.IsValid) return View(modelo);

        try
        {
            var usuario = _usuarios.Cadastrar(modelo.ParaUsuario(), modelo.Senha, modelo.ConfirmarSenha);
            await EntrarNoSistemaAsync(usuario);

            TempData["Mensagem"] = "Conta criada! Bem-vindo(a) ao Mundial Tickets.";
            return RedirectToAction("Index", "Home");
        }
        catch (RegraDeNegocioException ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return View(modelo);
        }
    }

    // ---------- sair ----------

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Sair()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);

        // Esvazia também o carrinho: o navegador pode ser de uso compartilhado.
        HttpContext.Session.Clear();

        TempData["Mensagem"] = "Você saiu da sua conta.";
        return RedirectToAction("Index", "Home");
    }

    [HttpGet]
    public IActionResult AcessoNegado() => View();

    // ---------- minha conta ----------

    [Authorize]
    [HttpGet]
    public IActionResult MinhaConta()
    {
        var usuario = _usuarios.ObterPorId(User.ObterUsuarioId());
        if (usuario is null) return RedirectToAction(nameof(Entrar));
        return View(UsuarioAtualizarDto.De(usuario));
    }

    [Authorize]
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> MinhaConta(UsuarioAtualizarDto modelo)
    {
        if (!ModelState.IsValid) return View(modelo);

        try
        {
            var usuario = _usuarios.Atualizar(User.ObterUsuarioId(), modelo.Nome, modelo.Email, modelo.Cpf, modelo.NovaSenha, modelo.ConfirmarNovaSenha);

            // O nome e o e-mail vão dentro do cookie: refaz o login para eles aparecerem atualizados.
            await EntrarNoSistemaAsync(usuario);

            TempData["Mensagem"] = "Dados atualizados.";
            return RedirectToAction(nameof(MinhaConta));
        }
        catch (RegraDeNegocioException ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return View(modelo);
        }
    }

    // "Excluir a conta" desativa o usuário (o banco não deixa apagar quem já comprou).
    [Authorize]
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Desativar()
    {
        _usuarios.Desativar(User.ObterUsuarioId());
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        HttpContext.Session.Clear();

        TempData["Mensagem"] = "Sua conta foi desativada.";
        return RedirectToAction("Index", "Home");
    }

    // ---------- apoio ----------

    // Grava o login no cookie: id, nome, e-mail e perfil (CLIENTE ou ADMIN).
    private async Task EntrarNoSistemaAsync(Usuario usuario)
    {
        var identidade = new ClaimsIdentity(new[]
        {
            new Claim(ClaimTypes.NameIdentifier, usuario.UsuarioID.ToString()),
            new Claim(ClaimTypes.Name, usuario.Nome),
            new Claim(ClaimTypes.Email, usuario.Email),
            new Claim(ClaimTypes.Role, usuario.Perfil)
        }, CookieAuthenticationDefaults.AuthenticationScheme);

        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(identidade),
            new AuthenticationProperties { IsPersistent = true });
    }
}
