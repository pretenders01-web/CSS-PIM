namespace MundialTickets.Negocio;

// Lançada quando uma regra de negócio é violada (e-mail repetido, assento já vendido...).
// Os controllers capturam esta exceção e mostram a mensagem para o usuário:
// na Web, como erro no formulário; na Api, como 400 Bad Request.
public class RegraDeNegocioException : Exception
{
    public RegraDeNegocioException(string mensagem) : base(mensagem) { }

    // Usada quando a regra foi violada por uma falha do banco (OperacaoNoBancoException):
    // a mensagem é mostrada ao usuário e o erro técnico fica em InnerException.
    public RegraDeNegocioException(string mensagem, Exception interna) : base(mensagem, interna) { }
}
