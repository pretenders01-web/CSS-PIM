using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using MundialTickets.Modelos.Dtos;
using MundialTickets.Repositorio.Contexto;
using MundialTickets.Repositorio.Interfaces;

namespace MundialTickets.Repositorio;

// Única classe que conversa com Venda, ItemVenda e QRCode.
// Exemplo da combinação sugerida no manual:
//   - Dapper para a stored procedure sp_RealizarCompra
//   - Entity Framework Core para as consultas
// A Venda, os itens, a troca do ingresso para VENDIDO e o QR code nascem dentro do banco
// (procedure e triggers); esta classe não grava nessas tabelas pelo EF.
public class VendaRepositorio : IVendaRepositorio
{
    private readonly AppDbContext _contexto;

    // INJEÇÃO DE DEPENDÊNCIA: o contexto do banco chega pronto, já com a connection string.
    public VendaRepositorio(AppDbContext contexto)
    {
        _contexto = contexto;
    }

    // ---------- Dapper + stored procedure ----------

    public List<CompraResultadoDto> RealizarCompra(int usuarioId, IEnumerable<int> ingressoIds, string metodoPagamento)
    {
        // Reaproveita a mesma conexão (e a mesma connection string) do EF.
        var conexao = _contexto.Database.GetDbConnection();

        // Se já existe uma transação aberta no contexto, o Dapper precisa participar dela.
        var transacao = _contexto.Database.CurrentTransaction?.GetDbTransaction();

        try
        {
            // Os valores vão separados do comando: isso é o que impede SQL Injection.
            // A procedure recebe os ids como um texto separado por vírgula.
            var linhas = conexao.Query<CompraResultadoDto>(
                "sp_RealizarCompra",
                new
                {
                    UsuarioID = usuarioId,
                    Ingressos = string.Join(",", ingressoIds),
                    MetodoPagamento = metodoPagamento
                },
                transaction: transacao,
                commandType: CommandType.StoredProcedure);

            return linhas.ToList();

            // A mesma chamada só com EF Core seria:
            // _contexto.Database.ExecuteSql($"EXEC sp_RealizarCompra @UsuarioID = {usuarioId}, ...");
            // (o EF não mapeia o resultado da procedure para um DTO tão direto quanto o Dapper)
        }
        catch (SqlException ex)
        {
            // Há dois tipos de falha vindo da procedure:
            //  1) As validações que ela faz ANTES de abrir a transação usam THROW com número
            //     próprio (50010 a 50013), e o número chega aqui. As mensagens do banco vêm sem
            //     acento, por isso cada número vira uma mensagem nossa.
            //  2) Qualquer erro DENTRO da transação (trigger, índice único, chave estrangeira)
            //     é relançado pelo CATCH da procedure com RAISERROR, que perde o número
            //     original (vira 50000). Nesse caso a distinção é pelo texto da trigger, escrito
            //     em português no script do banco.
            // O erro técnico completo continua em InnerException.
            var mensagem = ex.Number switch
            {
                50010 => "Informe ao menos um ingresso para realizar a compra.",
                50011 => "A lista de ingressos contém IDs inválidos ou vazios.",
                50012 => "Um ou mais ingressos informados não existem.",
                50013 => "A lista contém ingressos repetidos.",
                _ when ex.Message.Contains("não estão disponíveis")
                    => "Um ou mais ingressos não estão disponíveis para venda.",
                _ => "Não foi possível concluir a compra. Algum dos ingressos pode ter acabado de ser vendido. Tente novamente."
            };

            throw new OperacaoNoBancoException(mensagem, ex);
        }
    }

    // ---------- Entity Framework Core ----------

    // Parte dos QR codes do usuário e projeta direto no DTO: o EF monta um único SELECT
    // com só as colunas necessárias.
    public List<IngressoCompradoDto> ListarIngressosDoUsuario(int usuarioId) =>
        _contexto.QRCodes.AsNoTracking()
            .Where(q => q.Venda!.UsuarioID == usuarioId)
            .OrderBy(q => q.Ingresso!.Jogo!.DataHora)
            .Select(q => new IngressoCompradoDto
            {
                IngressoId = q.IngressoID,
                VendaId = q.VendaID,
                Partida = q.Ingresso!.Jogo!.TimeA + " x " + q.Ingresso.Jogo.TimeB,
                DataJogo = q.Ingresso.Jogo.DataHora,
                NomeSetor = q.Ingresso.Setor!.NomeSetor,
                NumeroAssento = q.Ingresso.NumeroAssento,
                PrecoPago = q.Venda!.Itens
                    .Where(i => i.IngressoID == q.IngressoID)
                    .Select(i => i.PrecoUnitario)
                    .FirstOrDefault(),
                CodigoQR = q.CodigoQR,
                DataExpiracao = q.DataExpiracao,
                Utilizado = q.Utilizado
            })
            .ToList();
}
