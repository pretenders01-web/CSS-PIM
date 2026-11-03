using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MundialTickets.Modelos.Constantes;

namespace MundialTickets.Web.Areas.Admin.Controllers;

// Base de todos os controllers da área de Administração (/Admin/...).
// Os dois atributos abaixo são herdados por cada controller da área:
//   [Area]      coloca o controller na área "Admin" (endereços /Admin/Estadios, /Admin/Jogos...);
//   [Authorize] só deixa entrar quem está logado com o perfil ADMIN. Quem está logado como
//               CLIENTE vai para "Acesso negado"; quem não está logado vai para o login.
[Area("Admin")]
[Authorize(Roles = PerfilUsuario.Admin)]
public abstract class AdminControllerBase : Controller
{
}
