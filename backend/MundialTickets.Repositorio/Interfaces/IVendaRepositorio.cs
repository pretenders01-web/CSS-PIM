using MundialTickets.Modelos;
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

    // O QR code de um código, já com o ingresso, o jogo e o setor. Devolve null se o código não existir.
    QRCode? ObterQRCodePorCodigo(string codigoQR);

    // Marca o QR code como utilizado, só se ele ainda não estiver. Devolve true quando marcou;
    // false quer dizer que outro leitor validou o mesmo ingresso um instante antes.
    bool MarcarQRCodeComoUtilizado(string codigoQR);
}
