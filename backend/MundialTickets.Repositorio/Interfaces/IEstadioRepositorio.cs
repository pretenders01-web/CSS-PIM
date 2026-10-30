using MundialTickets.Modelos;

namespace MundialTickets.Repositorio.Interfaces;

// Contrato do repositório. A camada Negocio conhece só esta interface,
// nunca a classe concreta — assim dá para trocar EF por Dapper sem mexer no negócio.
public interface IEstadioRepositorio
{
    List<Estadio> Listar();
    Estadio? ObterPorId(int id);
    bool NomeEmUsoNaCidade(string nome, string cidade, int? ignorarId = null);

    // True quando o estádio já tem setores ou jogos ligados a ele.
    bool PossuiVinculos(int id);

    void Adicionar(Estadio estadio);
    void Atualizar(Estadio estadio);
    void Remover(Estadio estadio);
}
