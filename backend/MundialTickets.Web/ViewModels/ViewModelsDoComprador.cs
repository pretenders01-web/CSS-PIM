using System.ComponentModel.DataAnnotations;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Web.Servicos;

namespace MundialTickets.Web.ViewModels;

// ViewModels: os objetos feitos para a TELA. Juntam o que cada página precisa mostrar (jogo,
// bandeiras, setores, assentos, total...), em vez de passar entidades do banco para a view.

// O formulário de login é o LoginDto (que traz as validações) mais o endereço de retorno.
public class LoginViewModel : LoginDto
{
    public string? ReturnUrl { get; set; }
}

// Um jogo pronto para ser mostrado em card: o DTO e o caminho da bandeira de cada time.
public class JogoCardViewModel
{
    public JogoDto Jogo { get; set; } = new();
    public string? BandeiraA { get; set; }
    public string? BandeiraB { get; set; }

    public static JogoCardViewModel De(JogoDto jogo) => new()
    {
        Jogo = jogo,
        BandeiraA = Bandeiras.Url(jogo.TimeA),
        BandeiraB = Bandeiras.Url(jogo.TimeB)
    };
}

// Home e lista de ingressos: os jogos em cards.
public class JogosViewModel
{
    public List<JogoCardViewModel> Jogos { get; set; } = new();
}

// Página de um jogo: os setores e, depois de escolher um, os assentos disponíveis dele.
public class JogoDetalhesViewModel
{
    public JogoCardViewModel Jogo { get; set; } = new();
    public List<SetorDisponibilidadeDto> Setores { get; set; } = new();
    public int? SetorSelecionadoId { get; set; }
    public SetorDisponibilidadeDto? SetorSelecionado => Setores.FirstOrDefault(s => s.SetorId == SetorSelecionadoId);
    public List<AssentoDisponivelDto> Assentos { get; set; } = new();

    // Assentos que o comprador já pôs no carrinho (aparecem marcados e não podem ser repetidos).
    public HashSet<int> NoCarrinho { get; set; } = new();
}

// Uma linha do carrinho. Preço e disponibilidade vêm do banco, não da sessão.
public class ItemCarrinhoViewModel
{
    public int IngressoId { get; set; }
    public string TimeA { get; set; } = string.Empty;
    public string TimeB { get; set; } = string.Empty;
    public string? BandeiraA { get; set; }
    public string? BandeiraB { get; set; }
    public DateTime DataJogo { get; set; }
    public string NomeSetor { get; set; } = string.Empty;
    public string NumeroAssento { get; set; } = string.Empty;
    public decimal Preco { get; set; }

    // False quando o assento foi vendido ou cancelado depois de entrar no carrinho.
    public bool Disponivel { get; set; }
}

public class CarrinhoViewModel
{
    public List<ItemCarrinhoViewModel> Itens { get; set; } = new();
    public bool TemIndisponivel => Itens.Any(i => !i.Disponivel);

    // O total só conta os assentos que ainda podem ser comprados.
    public decimal Total => Itens.Where(i => i.Disponivel).Sum(i => i.Preco);
    public int QuantidadeDisponivel => Itens.Count(i => i.Disponivel);
}

// Página de pagamento: o resumo do carrinho e a forma de pagamento escolhida.
public class PagamentoViewModel
{
    public CarrinhoViewModel Carrinho { get; set; } = new();

    [Display(Name = "Forma de pagamento")]
    [Required(ErrorMessage = "Escolha a forma de pagamento.")]
    public string MetodoPagamento { get; set; } = "PIX";
}

// Meus ingressos: o que o usuário já comprou, com o código do QR.
public class MeusIngressosViewModel
{
    public List<IngressoCompradoDto> Ingressos { get; set; } = new();
}
