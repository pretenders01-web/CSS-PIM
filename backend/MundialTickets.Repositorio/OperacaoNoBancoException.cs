namespace MundialTickets.Repositorio;

// Lançada quando o banco recusa uma operação (por exemplo, a stored procedure de compra).
// A mensagem já vem em português e pode ser mostrada ao usuário; o erro técnico do SQL
// Server fica em InnerException, para quem precisar investigar.
//
// Por que não usar a RegraDeNegocioException? Porque ela mora no projeto Negocio, que
// referencia o Repositorio, e uma camada de baixo não pode conhecer a de cima. O Negocio
// captura esta exceção e a converte em RegraDeNegocioException.
public class OperacaoNoBancoException : Exception
{
    public OperacaoNoBancoException(string mensagem, Exception? interna = null) : base(mensagem, interna) { }
}
