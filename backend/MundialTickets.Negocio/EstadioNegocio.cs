using MundialTickets.Modelos;
using MundialTickets.Repositorio.Interfaces;

namespace MundialTickets.Negocio;

// Aqui moram as regras de negócio do estádio.
// Web e Api chamam esta classe; esta classe chama o repositório.
// Nenhuma regra fica no controller nem na view.
public class EstadioNegocio
{
    private readonly IEstadioRepositorio _repositorio;

    // INJEÇÃO DE DEPENDÊNCIA: esta classe precisa de um repositório para trabalhar,
    // mas não cria um com "new". Ela PEDE no construtor, e o ASP.NET Core entrega.
    public EstadioNegocio(IEstadioRepositorio repositorio)
    {
        _repositorio = repositorio;
    }

    public List<Estadio> Listar() => _repositorio.Listar();

    public Estadio? ObterPorId(int id) => _repositorio.ObterPorId(id);

    public Estadio Cadastrar(Estadio estadio)
    {
        Normalizar(estadio);
        Validar(estadio, ignorarId: null);

        _repositorio.Adicionar(estadio);
        return estadio;
    }

    public void Atualizar(Estadio estadio)
    {
        var existente = _repositorio.ObterPorId(estadio.EstadioID)
            ?? throw new RegraDeNegocioException("Estádio não encontrado.");

        Normalizar(estadio);
        Validar(estadio, ignorarId: estadio.EstadioID);

        existente.Nome = estadio.Nome;
        existente.Cidade = estadio.Cidade;
        existente.CapacidadeTotal = estadio.CapacidadeTotal;

        _repositorio.Atualizar(existente);
    }

    // Devolve false quando o estádio não existe.
    // Lança RegraDeNegocioException se ele já tem setores ou jogos.
    public bool Remover(int id)
    {
        var estadio = _repositorio.ObterPorId(id);
        if (estadio is null) return false;

        if (_repositorio.PossuiVinculos(id))
            throw new RegraDeNegocioException("Não é possível excluir um estádio que já tem setores ou jogos.");

        _repositorio.Remover(estadio);
        return true;
    }

    // ---------- regras ----------

    private static void Normalizar(Estadio estadio)
    {
        estadio.Nome = estadio.Nome.Trim();
        estadio.Cidade = estadio.Cidade.Trim();
    }

    private void Validar(Estadio estadio, int? ignorarId)
    {
        if (estadio.CapacidadeTotal <= 0)
            throw new RegraDeNegocioException("A capacidade deve ser maior que zero.");

        if (_repositorio.NomeEmUsoNaCidade(estadio.Nome, estadio.Cidade, ignorarId))
            throw new RegraDeNegocioException("Já existe um estádio com este nome nesta cidade.");
    }
}
