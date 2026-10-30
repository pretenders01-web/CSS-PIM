using MundialTickets.Modelos;

namespace MundialTickets.Repositorio.Interfaces;

public interface ISetorRepositorio
{
    List<Setor> Listar();
    List<Setor> ListarPorEstadio(int estadioId);
    Setor? ObterPorId(int id);
    bool NomeEmUsoNoEstadio(int estadioId, string nomeSetor, int? ignorarId = null);

    // Soma das capacidades dos setores de um estádio (ignorando um setor, na alteração).
    int SomaCapacidadeDoEstadio(int estadioId, int? ignorarId = null);

    // True quando o setor já tem assentos ou ingressos ligados a ele.
    bool PossuiVinculos(int id);

    void Adicionar(Setor setor);
    void Atualizar(Setor setor);
    void Remover(Setor setor);
}
