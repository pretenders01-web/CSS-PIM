using MundialTickets.Modelos.Dtos;

namespace MundialTickets.Web.ViewModels;

// ViewModels da área de Administração. Cada página de entidade mostra, juntas, a TABELA com os
// registros e o FORMULÁRIO (vazio para cadastrar, preenchido para alterar).

// O formato comum das páginas de Estádio, Setor e Jogo.
public class PaginaAdminViewModel<TItem, TForm> where TForm : new()
{
    public List<TItem> Itens { get; set; } = new();
    public TForm Formulario { get; set; } = new();

    // Id do registro que está sendo alterado; nulo quando o formulário está cadastrando.
    public int? IdEmEdicao { get; set; }
    public bool EmEdicao => IdEmEdicao.HasValue;
}

public class SetoresPaginaViewModel : PaginaAdminViewModel<SetorDto, SetorSalvarDto>
{
    public List<EstadioDto> Estadios { get; set; } = new();
    public string NomeDoEstadio(int estadioId) => Estadios.FirstOrDefault(e => e.Id == estadioId)?.Nome ?? "?";
}

public class JogosPaginaViewModel : PaginaAdminViewModel<JogoDto, JogoSalvarDto>
{
    public List<EstadioDto> Estadios { get; set; } = new();
}

// Página de Assento: escolhe-se um setor, vê-se os assentos dele e há dois formulários:
// um assento por vez, e "criar vários".
public class AssentosPaginaViewModel
{
    public List<SetorDto> Setores { get; set; } = new();
    public List<EstadioDto> Estadios { get; set; } = new();
    public int? SetorId { get; set; }
    public SetorDto? SetorEscolhido => Setores.FirstOrDefault(s => s.Id == SetorId);
    public List<AssentoDto> Itens { get; set; } = new();

    public AssentoSalvarDto Formulario { get; set; } = new();
    public int? IdEmEdicao { get; set; }
    public bool EmEdicao => IdEmEdicao.HasValue;
    public AssentoLoteDto FormularioLote { get; set; } = new();

    public string RotuloDoSetor(SetorDto setor) =>
        $"{Estadios.FirstOrDefault(e => e.Id == setor.EstadioId)?.Nome ?? "?"} — {setor.NomeSetor}";
}

// Uma linha da tabela de ingressos da administração.
public class IngressoLinhaViewModel
{
    public int Id { get; set; }
    public string Partida { get; set; } = string.Empty;
    public string NomeSetor { get; set; } = string.Empty;
    public string NumeroAssento { get; set; } = string.Empty;
    public decimal PrecoFinal { get; set; }
    public string Status { get; set; } = string.Empty;
}

// Formulário do ingresso individual: o setor é descoberto a partir do assento escolhido.
public class NovoIngressoViewModel
{
    public int JogoID { get; set; }
    public int AssentoID { get; set; }
    public decimal PrecoFinal { get; set; }
}

// Um assento do estádio do jogo que ainda não tem ingresso, para a lista do formulário.
public class AssentoLivreViewModel
{
    public int AssentoId { get; set; }
    public string Rotulo { get; set; } = string.Empty;
    public decimal PrecoBase { get; set; }
}

public class IngressosPaginaViewModel
{
    public List<JogoDto> Jogos { get; set; } = new();
    public int? JogoId { get; set; }
    public string? Status { get; set; }
    public List<IngressoLinhaViewModel> Itens { get; set; } = new();

    // Só preenchida quando um jogo está escolhido no filtro.
    public List<AssentoLivreViewModel> AssentosLivres { get; set; } = new();
    public NovoIngressoViewModel Novo { get; set; } = new();
    public IngressoGerarDto Gerar { get; set; } = new();
}
