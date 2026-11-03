using System.Globalization;
using System.Text;

namespace MundialTickets.Web.Servicos;

// Liga o NOME de um time ao arquivo da bandeira em wwwroot/flags.
// O banco guarda só o nome do time ("México", "Estados Unidos"); a bandeira é resolvida aqui,
// por uma tabela de correspondência, sem coluna nova no banco. Time que não está na tabela
// devolve null, e a tela mostra um ícone genérico no lugar.
public static class Bandeiras
{
    // Chave: nome do time sem acento e em minúsculas. Valor: nome do arquivo (sem .svg).
    private static readonly Dictionary<string, string> Arquivos = new()
    {
        ["argentina"] = "argentina",
        ["brasil"] = "brazil",
        ["canada"] = "canada",
        ["chile"] = "chile",
        ["dinamarca"] = "denmark",
        ["franca"] = "france",
        ["alemanha"] = "germany",
        ["japao"] = "japan",
        ["mexico"] = "mexico",
        ["servia"] = "serbia",
        ["uruguai"] = "uruguay",
        ["estados unidos"] = "usa",
        ["eua"] = "usa"
    };

    // Devolve o caminho da bandeira (por exemplo, "/flags/brazil.svg") ou null se não houver.
    public static string? Url(string? time)
    {
        if (string.IsNullOrWhiteSpace(time)) return null;
        return Arquivos.TryGetValue(SemAcento(time.Trim()).ToLowerInvariant(), out var arquivo)
            ? $"/flags/{arquivo}.svg"
            : null;
    }

    private static string SemAcento(string texto)
    {
        var decomposto = texto.Normalize(NormalizationForm.FormD);
        var sb = new StringBuilder(decomposto.Length);
        foreach (var c in decomposto)
            if (CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark)
                sb.Append(c);
        return sb.ToString().Normalize(NormalizationForm.FormC);
    }
}
