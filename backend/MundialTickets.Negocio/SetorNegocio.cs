using MundialTickets.Modelos;
using MundialTickets.Repositorio.Interfaces;

namespace MundialTickets.Negocio;

// Regras do setor. Web e Api chamam esta classe; esta classe chama o repositório.
public class SetorNegocio
{
    private readonly ISetorRepositorio _setores;
    private readonly IEstadioRepositorio _estadios;
    private readonly IAssentoRepositorio _assentos;

    // INJEÇÃO DE DEPENDÊNCIA: os repositórios chegam prontos no construtor.
    public SetorNegocio(ISetorRepositorio setores, IEstadioRepositorio estadios, IAssentoRepositorio assentos)
    {
        _setores = setores;
        _estadios = estadios;
        _assentos = assentos;
    }

    public List<Setor> Listar() => _setores.Listar();

    public List<Setor> ListarPorEstadio(int estadioId) => _setores.ListarPorEstadio(estadioId);

    public Setor? ObterPorId(int id) => _setores.ObterPorId(id);

    public Setor Cadastrar(Setor setor)
    {
        Normalizar(setor);
        Validar(setor, ignorarId: null);

        _setores.Adicionar(setor);
        return setor;
    }

    public void Atualizar(Setor setor)
    {
        var existente = _setores.ObterPorId(setor.SetorID)
            ?? throw new RegraDeNegocioException("Setor não encontrado.");

        Normalizar(setor);
        Validar(setor, ignorarId: setor.SetorID);

        // Trocar o estádio de um setor que já tem assentos ou ingressos deixaria esses
        // registros apontando para um estádio ao qual o setor não pertence mais.
        if (setor.EstadioID != existente.EstadioID && _setores.PossuiVinculos(setor.SetorID))
            throw new RegraDeNegocioException("Não é possível trocar o estádio de um setor que já tem assentos ou ingressos.");

        // A capacidade não pode ficar menor que o número de assentos que o setor já tem.
        var assentosDoSetor = _assentos.ContarPorSetor(setor.SetorID);
        if (setor.Capacidade < assentosDoSetor)
            throw new RegraDeNegocioException($"O setor já tem {assentosDoSetor} assentos; a capacidade não pode ser menor que isso.");

        existente.EstadioID = setor.EstadioID;
        existente.NomeSetor = setor.NomeSetor;
        existente.Capacidade = setor.Capacidade;
        existente.PrecoBase = setor.PrecoBase;

        _setores.Atualizar(existente);
    }

    // Devolve false quando o setor não existe.
    // Lança RegraDeNegocioException se ele já tem assentos ou ingressos.
    public bool Remover(int id)
    {
        var setor = _setores.ObterPorId(id);
        if (setor is null) return false;

        if (_setores.PossuiVinculos(id))
            throw new RegraDeNegocioException("Não é possível excluir um setor que já tem assentos ou ingressos.");

        _setores.Remover(setor);
        return true;
    }

    // ---------- regras ----------

    private static void Normalizar(Setor setor)
    {
        setor.NomeSetor = (setor.NomeSetor ?? string.Empty).Trim();
    }

    private void Validar(Setor setor, int? ignorarId)
    {
        var estadio = _estadios.ObterPorId(setor.EstadioID)
            ?? throw new RegraDeNegocioException("Estádio não encontrado.");

        if (string.IsNullOrEmpty(setor.NomeSetor))
            throw new RegraDeNegocioException("Informe o nome do setor.");

        if (setor.Capacidade <= 0)
            throw new RegraDeNegocioException("A capacidade deve ser maior que zero.");

        if (setor.PrecoBase < 0)
            throw new RegraDeNegocioException("O preço base não pode ser negativo.");

        if (_setores.NomeEmUsoNoEstadio(setor.EstadioID, setor.NomeSetor, ignorarId))
            throw new RegraDeNegocioException("Já existe um setor com este nome neste estádio.");

        // A soma das capacidades dos setores não pode passar a capacidade total do estádio.
        var somaDosOutros = _setores.SomaCapacidadeDoEstadio(setor.EstadioID, ignorarId);
        if (somaDosOutros + setor.Capacidade > estadio.CapacidadeTotal)
            throw new RegraDeNegocioException(
                $"A soma das capacidades dos setores ({somaDosOutros + setor.Capacidade}) passaria a capacidade total do estádio ({estadio.CapacidadeTotal}).");
    }
}
