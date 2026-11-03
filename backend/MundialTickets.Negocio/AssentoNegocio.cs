using MundialTickets.Modelos;
using MundialTickets.Repositorio.Interfaces;

namespace MundialTickets.Negocio;

// Regras do assento. Web e Api chamam esta classe; esta classe chama o repositório.
public class AssentoNegocio
{
    private const int TamanhoMaximoDoNumero = 10;   // tamanho da coluna Assento.Numero

    private readonly IAssentoRepositorio _assentos;
    private readonly ISetorRepositorio _setores;

    // INJEÇÃO DE DEPENDÊNCIA: os repositórios chegam prontos no construtor.
    public AssentoNegocio(IAssentoRepositorio assentos, ISetorRepositorio setores)
    {
        _assentos = assentos;
        _setores = setores;
    }

    public List<Assento> ListarPorSetor(int setorId) => _assentos.ListarPorSetor(setorId);

    public Assento? ObterPorId(int id) => _assentos.ObterPorId(id);

    public Assento Cadastrar(Assento assento)
    {
        Normalizar(assento);
        Validar(assento, ignorarId: null);

        _assentos.Adicionar(assento);
        return assento;
    }

    public void Atualizar(Assento assento)
    {
        var existente = _assentos.ObterPorId(assento.AssentoID)
            ?? throw new RegraDeNegocioException("Assento não encontrado.");

        Normalizar(assento);
        Validar(assento, ignorarId: assento.AssentoID);

        // O ingresso guarda o setor do assento; mudar o assento de setor o deixaria incoerente.
        if (assento.SetorID != existente.SetorID && _assentos.PossuiIngresso(assento.AssentoID))
            throw new RegraDeNegocioException("Não é possível trocar o setor de um assento que já tem ingresso.");

        existente.SetorID = assento.SetorID;
        existente.Numero = assento.Numero;

        _assentos.Atualizar(existente);
    }

    // Devolve false quando o assento não existe.
    // Lança RegraDeNegocioException se ele já tem ingresso.
    public bool Remover(int id)
    {
        var assento = _assentos.ObterPorId(id);
        if (assento is null) return false;

        if (_assentos.PossuiIngresso(id))
            throw new RegraDeNegocioException("Não é possível excluir um assento que já tem ingresso.");

        _assentos.Remover(assento);
        return true;
    }

    // Criação em lote: cria os assentos prefixo+01 até prefixo+quantidade (por exemplo, A01 a A10)
    // e pula os números que o setor já tem. Ou entram todos ou nenhum.
    // Devolve os assentos criados. O prefixo é opcional (padrão "A").
    public List<Assento> CriarEmLote(int setorId, int quantidade, string? prefixo = null)
    {
        var setor = _setores.ObterPorId(setorId)
            ?? throw new RegraDeNegocioException("Setor não encontrado.");

        if (quantidade <= 0)
            throw new RegraDeNegocioException("A quantidade deve ser maior que zero.");

        prefixo = string.IsNullOrWhiteSpace(prefixo) ? "A" : prefixo.Trim().ToUpperInvariant();
        if (!prefixo.All(char.IsLetterOrDigit))
            throw new RegraDeNegocioException("O prefixo deve ter só letras e números.");

        // Dois dígitos no mínimo (A01); mais se a quantidade pedir (A001 para mais de 99).
        var largura = Math.Max(2, quantidade.ToString().Length);
        if (prefixo.Length + largura > TamanhoMaximoDoNumero)
            throw new RegraDeNegocioException($"O número do assento pode ter no máximo {TamanhoMaximoDoNumero} caracteres; use um prefixo menor ou uma quantidade menor.");

        var existentes = _assentos.ListarNumerosDoSetor(setorId).ToHashSet(StringComparer.OrdinalIgnoreCase);
        var novos = Enumerable.Range(1, quantidade)
            .Select(n => prefixo + n.ToString().PadLeft(largura, '0'))
            .Where(numero => !existentes.Contains(numero))
            .Select(numero => new Assento { SetorID = setorId, Numero = numero })
            .ToList();

        if (novos.Count == 0)
            throw new RegraDeNegocioException("Todos os assentos pedidos já existem neste setor.");

        if (existentes.Count + novos.Count > setor.Capacidade)
            throw new RegraDeNegocioException(
                $"O setor tem capacidade para {setor.Capacidade} assentos e já tem {existentes.Count}; não dá para criar mais {novos.Count}.");

        _assentos.AdicionarVarios(novos);
        return novos;
    }

    // ---------- regras ----------

    private static void Normalizar(Assento assento)
    {
        assento.Numero = (assento.Numero ?? string.Empty).Trim().ToUpperInvariant();
    }

    private void Validar(Assento assento, int? ignorarId)
    {
        var setor = _setores.ObterPorId(assento.SetorID)
            ?? throw new RegraDeNegocioException("Setor não encontrado.");

        if (string.IsNullOrEmpty(assento.Numero))
            throw new RegraDeNegocioException("Informe o número do assento.");

        if (assento.Numero.Length > TamanhoMaximoDoNumero)
            throw new RegraDeNegocioException($"O número do assento pode ter no máximo {TamanhoMaximoDoNumero} caracteres.");

        if (_assentos.NumeroEmUsoNoSetor(assento.SetorID, assento.Numero, ignorarId))
            throw new RegraDeNegocioException("Já existe um assento com este número neste setor.");

        // O total de assentos do setor não pode passar a capacidade dele. Na alteração, o próprio
        // assento só conta como novo se estiver mudando de setor.
        var jaNoSetor = _assentos.ContarPorSetor(assento.SetorID);
        var existente = ignorarId.HasValue ? _assentos.ObterPorId(ignorarId.Value) : null;
        var contaComoNovo = existente is null || existente.SetorID != assento.SetorID;
        if (contaComoNovo && jaNoSetor + 1 > setor.Capacidade)
            throw new RegraDeNegocioException($"O setor já tem todos os {setor.Capacidade} assentos da sua capacidade.");
    }
}
