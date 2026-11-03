using MundialTickets.Modelos;
using MundialTickets.Modelos.Constantes;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Repositorio.Interfaces;

namespace MundialTickets.Negocio;

// Regras do ingresso: o CRUD da administração, a geração em lote e as consultas do comprador
// (setores de um jogo com vagas, e assentos disponíveis de um setor).
public class IngressoNegocio
{
    private static readonly string[] StatusValidos =
    {
        StatusIngresso.Disponivel, StatusIngresso.Reservado, StatusIngresso.Vendido, StatusIngresso.Cancelado
    };

    private readonly IIngressoRepositorio _ingressos;
    private readonly IJogoRepositorio _jogos;
    private readonly ISetorRepositorio _setores;
    private readonly IAssentoRepositorio _assentos;

    // INJEÇÃO DE DEPENDÊNCIA: os repositórios chegam prontos no construtor.
    public IngressoNegocio(IIngressoRepositorio ingressos, IJogoRepositorio jogos, ISetorRepositorio setores, IAssentoRepositorio assentos)
    {
        _ingressos = ingressos;
        _jogos = jogos;
        _setores = setores;
        _assentos = assentos;
    }

    // ---------- administração ----------

    public List<Ingresso> Listar(int? jogoId = null, string? status = null)
    {
        status = string.IsNullOrWhiteSpace(status) ? null : status.Trim().ToUpperInvariant();
        if (status is not null && !StatusValidos.Contains(status))
            throw new RegraDeNegocioException("Situação inválida.");

        return _ingressos.Listar(jogoId, status);
    }

    public Ingresso? ObterPorId(int id) => _ingressos.ObterPorId(id);

    // Vários ingressos de uma vez, com Jogo, Setor e Assento (usado para mostrar o carrinho).
    // Ids que não existem mais simplesmente não voltam na lista.
    public List<Ingresso> ListarPorIds(IEnumerable<int> ids) => _ingressos.ObterPorIds(ids);

    // Cria um ingresso individual. O número do assento é copiado do próprio assento e o
    // status começa DISPONIVEL: nenhum dos dois vem da tela.
    public Ingresso Cadastrar(Ingresso ingresso)
    {
        var assento = ValidarOrigem(ingresso.JogoID, ingresso.SetorID, ingresso.AssentoID);
        ValidarPreco(ingresso.PrecoFinal);

        if (_ingressos.ExisteParaAssento(ingresso.JogoID, ingresso.SetorID, assento.AssentoID))
            throw new RegraDeNegocioException("Já existe um ingresso para este assento neste jogo.");

        ingresso.NumeroAssento = assento.Numero;
        ingresso.Status = StatusIngresso.Disponivel;

        _ingressos.Adicionar(ingresso);
        return ingresso;
    }

    // Só o preço pode ser alterado, e só enquanto o ingresso está disponível.
    public Ingresso AtualizarPreco(int id, decimal precoFinal)
    {
        var ingresso = _ingressos.ObterPorId(id)
            ?? throw new RegraDeNegocioException("Ingresso não encontrado.");

        if (ingresso.Status != StatusIngresso.Disponivel)
            throw new RegraDeNegocioException("Só é possível alterar o preço de um ingresso disponível.");

        ValidarPreco(precoFinal);

        ingresso.PrecoFinal = precoFinal;
        _ingressos.Atualizar(ingresso);
        return ingresso;
    }

    public Ingresso Cancelar(int id)
    {
        var ingresso = _ingressos.ObterPorId(id)
            ?? throw new RegraDeNegocioException("Ingresso não encontrado.");

        if (ingresso.Status == StatusIngresso.Vendido)
            throw new RegraDeNegocioException("Um ingresso vendido não pode ser cancelado.");
        if (ingresso.Status == StatusIngresso.Cancelado)
            throw new RegraDeNegocioException("Este ingresso já está cancelado.");

        ingresso.Status = StatusIngresso.Cancelado;
        _ingressos.Atualizar(ingresso);
        return ingresso;
    }

    // Devolve false quando o ingresso não existe.
    // Só exclui ingresso DISPONIVEL ou CANCELADO e que nunca entrou em uma venda.
    public bool Remover(int id)
    {
        var ingresso = _ingressos.ObterPorId(id);
        if (ingresso is null) return false;

        if (_ingressos.PossuiVenda(id) || ingresso.Status == StatusIngresso.Vendido)
            throw new RegraDeNegocioException("Não é possível excluir um ingresso que já foi vendido.");

        _ingressos.Remover(ingresso);
        return true;
    }

    // Geração em lote: cria um ingresso por assento de todos os setores do estádio do jogo,
    // com o preço base do setor, e pula os assentos que já têm ingresso neste jogo.
    // Pode ser repetida sem duplicar. Devolve quantos ingressos foram criados.
    public int GerarParaJogo(int jogoId)
    {
        var jogo = _jogos.ObterPorId(jogoId)
            ?? throw new RegraDeNegocioException("Jogo não encontrado.");

        var setores = _setores.ListarPorEstadio(jogo.EstadioID);
        if (setores.Count == 0)
            throw new RegraDeNegocioException("O estádio deste jogo não tem setores cadastrados.");

        var jaTemIngresso = _ingressos.ListarAssentoIdsComIngresso(jogoId).ToHashSet();
        var novos = new List<Ingresso>();
        var totalDeAssentos = 0;

        foreach (var setor in setores)
        {
            var assentos = _assentos.ListarPorSetor(setor.SetorID);
            totalDeAssentos += assentos.Count;
            if (assentos.Count > 0 && setor.PrecoBase <= 0)
                throw new RegraDeNegocioException($"O setor {setor.NomeSetor} está com preço base zero; defina o preço antes de gerar os ingressos.");

            foreach (var assento in assentos.Where(a => !jaTemIngresso.Contains(a.AssentoID)))
            {
                novos.Add(new Ingresso
                {
                    JogoID = jogoId,
                    SetorID = setor.SetorID,
                    AssentoID = assento.AssentoID,
                    NumeroAssento = assento.Numero,
                    PrecoFinal = setor.PrecoBase,
                    Status = StatusIngresso.Disponivel
                });
            }
        }

        if (totalDeAssentos == 0)
            throw new RegraDeNegocioException("O estádio deste jogo não tem assentos cadastrados.");

        if (novos.Count > 0)
            _ingressos.AdicionarVarios(novos);

        return novos.Count;
    }

    // ---------- comprador ----------

    // Os setores do estádio do jogo, com o preço e quantos assentos ainda estão disponíveis.
    // Setor sem vagas aparece com zero.
    public List<SetorDisponibilidadeDto> ListarSetoresDoJogo(int jogoId)
    {
        var jogo = _jogos.ObterPorId(jogoId)
            ?? throw new RegraDeNegocioException("Jogo não encontrado.");

        var disponiveis = _ingressos.ContarDisponiveisPorSetor(jogoId);

        return _setores.ListarPorEstadio(jogo.EstadioID)
            .Select(s => new SetorDisponibilidadeDto
            {
                SetorId = s.SetorID,
                NomeSetor = s.NomeSetor,
                PrecoBase = s.PrecoBase,
                AssentosDisponiveis = disponiveis.GetValueOrDefault(s.SetorID)
            })
            .ToList();
    }

    // Os assentos disponíveis de um setor de um jogo, já ligados ao ingresso que será comprado.
    public List<AssentoDisponivelDto> ListarAssentosDisponiveis(int jogoId, int setorId)
    {
        var jogo = _jogos.ObterPorId(jogoId)
            ?? throw new RegraDeNegocioException("Jogo não encontrado.");
        var setor = _setores.ObterPorId(setorId)
            ?? throw new RegraDeNegocioException("Setor não encontrado.");

        if (setor.EstadioID != jogo.EstadioID)
            throw new RegraDeNegocioException("O setor não pertence ao estádio do jogo.");

        return _ingressos.ListarDisponiveis(jogoId, setorId)
            .Select(i => new AssentoDisponivelDto
            {
                IngressoId = i.IngressoID,
                AssentoId = i.AssentoID!.Value,
                Numero = i.NumeroAssento ?? i.Assento?.Numero ?? string.Empty,
                Preco = i.PrecoFinal
            })
            .ToList();
    }

    // ---------- regras ----------

    // Confere que o jogo, o setor e o assento existem e combinam entre si.
    // O banco aceita ingresso sem assento, mas o sistema vende por assento escolhido.
    private Assento ValidarOrigem(int jogoId, int setorId, int? assentoId)
    {
        var jogo = _jogos.ObterPorId(jogoId)
            ?? throw new RegraDeNegocioException("Jogo não encontrado.");
        var setor = _setores.ObterPorId(setorId)
            ?? throw new RegraDeNegocioException("Setor não encontrado.");

        if (setor.EstadioID != jogo.EstadioID)
            throw new RegraDeNegocioException("O setor não pertence ao estádio do jogo.");

        if (assentoId is null)
            throw new RegraDeNegocioException("Escolha o assento.");

        var assento = _assentos.ObterPorId(assentoId.Value)
            ?? throw new RegraDeNegocioException("Assento não encontrado.");

        if (assento.SetorID != setor.SetorID)
            throw new RegraDeNegocioException("O assento não pertence ao setor escolhido.");

        return assento;
    }

    private static void ValidarPreco(decimal preco)
    {
        if (preco <= 0)
            throw new RegraDeNegocioException("O preço do ingresso deve ser maior que zero.");
    }
}
