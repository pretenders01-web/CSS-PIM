using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using MundialTickets.Negocio;

namespace MundialTickets.Api.Filtros;

// Transforma, em um só lugar, a RegraDeNegocioException lançada pelo Negócio em
// "400 Bad Request" com a mensagem: { "erro": "..." }.
// Sem este filtro, cada ação de cada controller precisaria de um try/catch igual.
public class RegraDeNegocioFiltro : IExceptionFilter
{
    public void OnException(ExceptionContext contexto)
    {
        if (contexto.Exception is RegraDeNegocioException ex)
        {
            contexto.Result = new BadRequestObjectResult(new { erro = ex.Message });
            contexto.ExceptionHandled = true;
        }
    }
}
