using MundialTickets.Modelos.Dtos;

namespace MundialTickets.Repositorio.Interfaces;

public interface IVendaRepositorio
{
    // Executa a stored procedure sp_RealizarCompra (com Dapper).
    // Devolve uma linha por ingresso comprado, com o código do QR.
    // Lança OperacaoNoBancoException se o banco recusar a compra.
    List<CompraResultadoDto> RealizarCompra(int usuarioId, IEnumerable<int> ingressoIds, string metodoPagamento);

    // Ingressos comprados por um usuário, com o código do QR, do jogo mais próximo ao mais distante.
    List<IngressoCompradoDto> ListarIngressosDoUsuario(int usuarioId);
}
