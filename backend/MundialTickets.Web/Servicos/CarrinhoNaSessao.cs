using System.Text.Json;

namespace MundialTickets.Web.Servicos;

// O carrinho de compras fica na SESSÃO do ASP.NET Core (no servidor, ligada ao navegador por um
// cookie), como uma lista de IngressoID. Só os ids são guardados: o preço e a disponibilidade são
// sempre lidos do banco quando o carrinho é mostrado, então o carrinho nunca fica com preço velho.
public static class CarrinhoNaSessao
{
    private const string Chave = "carrinho";

    public static List<int> Obter(ISession sessao)
    {
        var json = sessao.GetString(Chave);
        return string.IsNullOrEmpty(json) ? new List<int>() : JsonSerializer.Deserialize<List<int>>(json) ?? new List<int>();
    }

    public static int Contar(ISession sessao) => Obter(sessao).Count;

    // Acrescenta os ingressos sem repetir os que já estão no carrinho.
    public static void Adicionar(ISession sessao, IEnumerable<int> ingressoIds)
    {
        var carrinho = Obter(sessao);
        foreach (var id in ingressoIds.Where(i => i > 0).Distinct())
            if (!carrinho.Contains(id)) carrinho.Add(id);
        Salvar(sessao, carrinho);
    }

    public static void Remover(ISession sessao, int ingressoId)
    {
        var carrinho = Obter(sessao);
        carrinho.Remove(ingressoId);
        Salvar(sessao, carrinho);
    }

    public static void Limpar(ISession sessao) => sessao.Remove(Chave);

    private static void Salvar(ISession sessao, List<int> carrinho) =>
        sessao.SetString(Chave, JsonSerializer.Serialize(carrinho));
}
