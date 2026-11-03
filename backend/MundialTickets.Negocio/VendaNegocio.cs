using MundialTickets.Modelos;
using MundialTickets.Modelos.Constantes;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Modelos.Pagamentos;
using MundialTickets.Repositorio;
using MundialTickets.Repositorio.Interfaces;

namespace MundialTickets.Negocio;

// Regras da compra. É aqui que a stored procedure sp_RealizarCompra é disparada, e só depois
// de todas as conferências abaixo passarem e do pagamento (simulado) ser aprovado.
public class VendaNegocio
{
    private readonly IVendaRepositorio _vendas;
    private readonly IIngressoRepositorio _ingressos;
    private readonly IUsuarioRepositorio _usuarios;
    private readonly IEnumerable<IMetodoPagamento> _metodos;

    // INJEÇÃO DE DEPENDÊNCIA: os repositórios e as formas de pagamento chegam prontos.
    // Quem recebe um IMetodoPagamento não sabe se é Pix, cartão ou boleto (polimorfismo).
    public VendaNegocio(
        IVendaRepositorio vendas,
        IIngressoRepositorio ingressos,
        IUsuarioRepositorio usuarios,
        IEnumerable<IMetodoPagamento> metodos)
    {
        _vendas = vendas;
        _ingressos = ingressos;
        _usuarios = usuarios;
        _metodos = metodos;
    }

    // Faz a compra de um ou mais ingressos e devolve uma linha por ingresso, com o código do QR.
    // O comprador é sempre o usuário logado (usuarioId vem do cookie ou do token, nunca do pedido).
    public List<CompraResultadoDto> Comprar(int usuarioId, IEnumerable<int> ingressoIds, string metodoPagamento)
    {
        var ids = (ingressoIds ?? Enumerable.Empty<int>()).ToList();

        // 1 e 2. A lista não pode ser vazia nem ter o mesmo ingresso duas vezes.
        //        (O banco recusa ambos, mas com mensagens técnicas.)
        if (ids.Count == 0)
            throw new RegraDeNegocioException("Escolha ao menos um ingresso.");
        if (ids.Distinct().Count() != ids.Count)
            throw new RegraDeNegocioException("A lista contém ingressos repetidos.");

        // 3. O comprador existe e está ativo.
        var usuario = _usuarios.ObterPorId(usuarioId)
            ?? throw new RegraDeNegocioException("Usuário não encontrado.");
        if (!usuario.Ativo)
            throw new RegraDeNegocioException("Esta conta está desativada.");

        // 4. Todos os ingressos existem. Sem isto o banco falharia com "PrecoUnitario nulo".
        var ingressos = _ingressos.ObterPorIds(ids);
        if (ingressos.Count != ids.Count)
            throw new RegraDeNegocioException("Um ou mais ingressos informados não existem.");

        // 5. Todos estão disponíveis. A mensagem diz qual assento deixou de estar, porque não há
        //    reserva: vale a primeira compra concluída.
        var indisponiveis = ingressos.Where(i => i.Status != StatusIngresso.Disponivel).ToList();
        if (indisponiveis.Count > 0)
        {
            var assentos = string.Join("; ", indisponiveis.Select(Descrever));
            throw new RegraDeNegocioException(
                indisponiveis.Count == 1
                    ? $"Este assento não está mais disponível: {assentos}."
                    : $"Estes assentos não estão mais disponíveis: {assentos}.");
        }

        // 6. A forma de pagamento é conhecida.
        var metodo = _metodos.FirstOrDefault(m => string.Equals(m.Nome, metodoPagamento?.Trim(), StringComparison.OrdinalIgnoreCase))
            ?? throw new RegraDeNegocioException("Forma de pagamento não reconhecida.");

        // 7. Pagamento simulado. O total vem do preço gravado em cada ingresso, nunca do pedido.
        var total = ingressos.Sum(i => i.PrecoFinal);
        if (!metodo.ProcessarPagamento(total))
            throw new RegraDeNegocioException(
                $"O pagamento por {metodo.Nome} não é aprovado na hora, então a compra não foi feita. Escolha outra forma de pagamento.");

        // 8. Aprovado: dispara a stored procedure. Se o banco ainda recusar (por exemplo, outro
        //    comprador levou o assento um instante antes), a falha vira uma mensagem de negócio.
        try
        {
            return _vendas.RealizarCompra(usuarioId, ids, metodo.Nome);
        }
        catch (OperacaoNoBancoException ex)
        {
            throw new RegraDeNegocioException(ex.Message, ex);
        }
    }

    // Os ingressos que o usuário já comprou, com o código do QR.
    public List<IngressoCompradoDto> ListarIngressosDoUsuario(int usuarioId) =>
        _vendas.ListarIngressosDoUsuario(usuarioId);

    // Texto curto para as mensagens: "A01 do setor X (Brasil x Sérvia)".
    private static string Descrever(Ingresso ingresso)
    {
        var partida = ingresso.Jogo is null ? "jogo" : $"{ingresso.Jogo.TimeA} x {ingresso.Jogo.TimeB}";
        var assento = ingresso.NumeroAssento ?? ingresso.Assento?.Numero ?? "sem assento";
        return $"{assento} do setor {ingresso.Setor?.NomeSetor ?? "?"} ({partida})";
    }
}
