using MundialTickets.Modelos;

namespace MundialTickets.Repositorio.Interfaces;

public interface IAssentoRepositorio
{
    List<Assento> ListarPorSetor(int setorId);
    Assento? ObterPorId(int id);
    bool NumeroEmUsoNoSetor(int setorId, string numero, int? ignorarId = null);
    int ContarPorSetor(int setorId);

    // Números dos assentos que o setor já tem (para a criação em lote não repetir).
    List<string> ListarNumerosDoSetor(int setorId);

    // True quando o assento já tem ingresso.
    bool PossuiIngresso(int id);

    void Adicionar(Assento assento);

    // Grava todos de uma vez, em uma única operação: ou entram todos ou nenhum.
    void AdicionarVarios(IEnumerable<Assento> assentos);

    void Atualizar(Assento assento);
    void Remover(Assento assento);
}
