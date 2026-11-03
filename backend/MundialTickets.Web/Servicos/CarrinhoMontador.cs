using MundialTickets.Modelos.Constantes;
using MundialTickets.Negocio;
using MundialTickets.Web.ViewModels;

namespace MundialTickets.Web.Servicos;

// Monta o CarrinhoViewModel a partir dos ids guardados na sessão. Os dados (jogo, setor, assento,
// preço e se ainda está disponível) vêm do banco, pelo Negócio; a sessão só guarda os ids.
public static class CarrinhoMontador
{
    public static CarrinhoViewModel Montar(IngressoNegocio ingressos, ISession sessao)
    {
        var ids = CarrinhoNaSessao.Obter(sessao);
        var carrinho = new CarrinhoViewModel();
        if (ids.Count == 0) return carrinho;

        var porId = ingressos.ListarPorIds(ids).ToDictionary(i => i.IngressoID);

        foreach (var id in ids)
        {
            // Ingresso que não existe mais no banco sai do carrinho em silêncio.
            if (!porId.TryGetValue(id, out var ingresso))
            {
                CarrinhoNaSessao.Remover(sessao, id);
                continue;
            }

            carrinho.Itens.Add(new ItemCarrinhoViewModel
            {
                IngressoId = ingresso.IngressoID,
                TimeA = ingresso.Jogo?.TimeA ?? string.Empty,
                TimeB = ingresso.Jogo?.TimeB ?? string.Empty,
                BandeiraA = Bandeiras.Url(ingresso.Jogo?.TimeA),
                BandeiraB = Bandeiras.Url(ingresso.Jogo?.TimeB),
                DataJogo = ingresso.Jogo?.DataHora ?? default,
                NomeSetor = ingresso.Setor?.NomeSetor ?? string.Empty,
                NumeroAssento = ingresso.NumeroAssento ?? ingresso.Assento?.Numero ?? string.Empty,
                Preco = ingresso.PrecoFinal,
                Disponivel = ingresso.Status == StatusIngresso.Disponivel
            });
        }

        return carrinho;
    }
}
