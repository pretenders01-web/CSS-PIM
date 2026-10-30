using MundialTickets.Modelos;

namespace MundialTickets.Repositorio.Interfaces;

public interface IIngressoRepositorio
{
    // Lista com Jogo, Setor e Assento carregados; os dois filtros são opcionais.
    List<Ingresso> Listar(int? jogoId = null, string? status = null);

    Ingresso? ObterPorId(int id);

    // Vários ingressos de uma vez (para validar uma compra), com Jogo, Setor e Assento.
    List<Ingresso> ObterPorIds(IEnumerable<int> ids);

    // Ingressos DISPONIVEL de um setor de um jogo, com o Assento, ordenados pelo número.
    // Só entram os que têm assento, porque o comprador escolhe o assento.
    List<Ingresso> ListarDisponiveis(int jogoId, int setorId);

    // Quantos ingressos DISPONIVEL com assento cada setor tem em um jogo (chave = SetorID).
    Dictionary<int, int> ContarDisponiveisPorSetor(int jogoId);

    // True se já existe ingresso para este jogo, setor e assento.
    bool ExisteParaAssento(int jogoId, int setorId, int assentoId, int? ignorarId = null);

    // IDs dos assentos que já têm ingresso neste jogo (para a geração em lote não repetir).
    List<int> ListarAssentoIdsComIngresso(int jogoId);

    // True quando o ingresso já está em alguma venda.
    bool PossuiVenda(int id);

    void Adicionar(Ingresso ingresso);

    // Grava todos de uma vez, em uma única operação: ou entram todos ou nenhum.
    void AdicionarVarios(IEnumerable<Ingresso> ingressos);

    void Atualizar(Ingresso ingresso);
    void Remover(Ingresso ingresso);
}
